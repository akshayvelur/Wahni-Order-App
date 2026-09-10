import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wahniorderapp/bloc/cart/cart_bloc.dart';
import 'package:wahniorderapp/bloc/cart/cart_event.dart';
import 'package:wahniorderapp/bloc/cart/cart_state.dart';
import 'package:wahniorderapp/bloc/product/product_bloc.dart';
import 'package:wahniorderapp/bloc/product/product_event.dart';
import 'package:wahniorderapp/bloc/product/product_state.dart';
import 'package:wahniorderapp/data/datasources/local_database.dart';
import 'package:wahniorderapp/data/models/product_model.dart';
import 'package:wahniorderapp/screens/cart/cart_screen.dart';
import 'package:wahniorderapp/screens/main_screen.dart';
import 'package:wahniorderapp/screens/product_list/product_list_screen.dart';

class FakeProductBloc extends Bloc<ProductEvent, ProductState>
    implements ProductBloc {
  FakeProductBloc(super.initialState);
}

class FakeCartBloc extends Bloc<CartEvent, CartState> implements CartBloc {
  FakeCartBloc([super.initialState = const CartInitial()]) {
    on<UpdateQuantity>((event, emit) {
      final updated = Map<int, int>.from(state.quantities);
      if (event.quantity <= 0) {
        updated.remove(event.productId);
      } else {
        updated[event.productId] = event.quantity > 9999
            ? 9999
            : event.quantity;
      }
      emit(CartLoaded(updated));
    });

    on<RemoveFromCart>((event, emit) {
      final updated = Map<int, int>.from(state.quantities)
        ..remove(event.productId);
      emit(CartLoaded(updated));
    });

    on<AddToCart>((event, emit) {
      final updated = Map<int, int>.from(state.quantities);
      final current = updated[event.productId] ?? 0;
      updated[event.productId] = current + 1;
      emit(CartLoaded(updated));
    });
  }
}

void main() {
  const productA = ProductModel(
    id: 1,
    title: 'Product A',
    price: 10.0,
    image: 'https://fakestoreapi.com/img/a.jpg',
  );
  const productB = ProductModel(
    id: 2,
    title: 'Product B',
    price: 20.0,
    image: 'https://fakestoreapi.com/img/b.jpg',
  );
  const productC = ProductModel(
    id: 3,
    title: 'Product C',
    price: 30.0,
    image: 'https://fakestoreapi.com/img/c.jpg',
  );

  group('Cart AppBar Badge & Navigation', () {
    testWidgets(
      'Badge displays CartBloc.uniqueItems (NOT totalQuantity). Example: A x 5, B x 3, C x 2 => Badge = 3',
      (tester) async {
        final fakeProductBloc = FakeProductBloc(
          const ProductSuccess([productA, productB, productC]),
        );
        // Product A x 5, Product B x 3, Product C x 2
        // uniqueItems = 3, totalQuantity = 10
        final fakeCartBloc = FakeCartBloc(const CartLoaded({1: 5, 2: 3, 3: 2}));

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<ProductBloc>.value(value: fakeProductBloc),
                BlocProvider<CartBloc>.value(value: fakeCartBloc),
              ],
              child: const ProductListScreen(),
            ),
          ),
        );

        // Verify badge displays uniqueItems = 3 (NOT 10)
        expect(find.byKey(const ValueKey('appbar_cart_badge')), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('10'), findsNothing);
      },
    );

    testWidgets(
      'Badge updates immediately on add, remove, and quantity change',
      (tester) async {
        final fakeProductBloc = FakeProductBloc(
          const ProductSuccess([productA, productB]),
        );
        final fakeCartBloc = FakeCartBloc(const CartInitial());

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<ProductBloc>.value(value: fakeProductBloc),
                BlocProvider<CartBloc>.value(value: fakeCartBloc),
              ],
              child: const ProductListScreen(),
            ),
          ),
        );

        // Initially empty -> no badge visible
        final badgeFinder = find.byKey(
          const ValueKey('appbar_cart_badge_count'),
        );
        expect(badgeFinder, findsNothing);

        // 1. Add Product A -> uniqueItems becomes 1
        fakeCartBloc.add(const AddToCart(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('1'), findsOneWidget);

        // 2. Add Product A again -> uniqueItems remains 1 (quantity is 2)
        fakeCartBloc.add(const AddToCart(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('1'), findsOneWidget);

        // 3. Add Product B -> uniqueItems becomes 2
        fakeCartBloc.add(const AddToCart(2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('2'), findsOneWidget);

        // 4. Remove Product A (quantity 0) -> uniqueItems drops to 1
        fakeCartBloc.add(const UpdateQuantity(productId: 1, quantity: 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('1'), findsOneWidget);

        // 5. Remove Product B -> uniqueItems becomes 0 -> badge disappears
        fakeCartBloc.add(const RemoveFromCart(2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          find.byKey(const ValueKey('appbar_cart_badge_count')),
          findsNothing,
        );
      },
    );

    testWidgets('Tapping the cart icon navigates to CartScreen', (
      tester,
    ) async {
      bool cartOpened = false;
      final fakeProductBloc = FakeProductBloc(const ProductSuccess([productA]));
      final fakeCartBloc = FakeCartBloc(const CartLoaded({1: 1}));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ProductBloc>.value(value: fakeProductBloc),
              BlocProvider<CartBloc>.value(value: fakeCartBloc),
            ],
            child: ProductListScreen(onOpenCart: () => cartOpened = true),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('appbar_cart_button')));
      expect(cartOpened, isTrue);
    });

    testWidgets('Tapping cart icon in MainScreen switches tab to CartScreen', (
      tester,
    ) async {
      final fakeProductBloc = FakeProductBloc(const ProductSuccess([productA]));
      final fakeCartBloc = FakeCartBloc(const CartLoaded({1: 2}));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ProductBloc>.value(value: fakeProductBloc),
              BlocProvider<CartBloc>.value(value: fakeCartBloc),
            ],
            child: const MainScreen(),
          ),
        ),
      );

      // Initially on Product Listing
      expect(find.text('Wahni Products'), findsOneWidget);

      // Tap AppBar cart icon
      await tester.tap(find.byKey(const ValueKey('appbar_cart_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now on CartScreen
      expect(find.text('My Cart'), findsOneWidget);
      expect(find.text('Product A'), findsOneWidget);
    });
  });

  group('Directly Type Quantity & Edge Cases', () {
    testWidgets(
      'Tapping quantity in CartItemTile opens dialog and updates quantity',
      (tester) async {
        final fakeProductBloc = FakeProductBloc(
          const ProductSuccess([productA]),
        );
        final fakeCartBloc = FakeCartBloc(const CartLoaded({1: 3}));

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<ProductBloc>.value(value: fakeProductBloc),
                BlocProvider<CartBloc>.value(value: fakeCartBloc),
              ],
              child: const CartScreen(),
            ),
          ),
        );

        // Verify current quantity is 3
        expect(find.text('3'), findsOneWidget);

        // Tap quantity badge to open edit dialog
        await tester.tap(
          find.byKey(const ValueKey('cart_item_quantity_tap_1')),
        );
        await tester.pumpAndSettle();

        // Dialog is open
        expect(find.text('Edit Quantity'), findsOneWidget);

        // Clear and type 8
        await tester.enterText(
          find.byKey(const ValueKey('quantity_input_field')),
          '8',
        );
        await tester.tap(find.byKey(const ValueKey('quantity_submit_button')));
        await tester.pumpAndSettle();

        // Quantity should now be 8
        expect(find.text('8'), findsOneWidget);
        expect(fakeCartBloc.state.getQuantity(1), 8);
      },
    );

    testWidgets('Typing 0 in quantity dialog removes item from cart', (
      tester,
    ) async {
      final fakeProductBloc = FakeProductBloc(const ProductSuccess([productA]));
      final fakeCartBloc = FakeCartBloc(const CartLoaded({1: 2}));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ProductBloc>.value(value: fakeProductBloc),
              BlocProvider<CartBloc>.value(value: fakeCartBloc),
            ],
            child: const CartScreen(),
          ),
        ),
      );

      // Tap quantity to edit
      await tester.tap(find.byKey(const ValueKey('cart_item_quantity_tap_1')));
      await tester.pumpAndSettle();

      // Enter 0
      await tester.enterText(
        find.byKey(const ValueKey('quantity_input_field')),
        '0',
      );
      await tester.tap(find.byKey(const ValueKey('quantity_submit_button')));
      await tester.pumpAndSettle();

      // Item is removed, empty state displayed
      expect(find.text('Product A'), findsNothing);
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(fakeCartBloc.state.getQuantity(1), 0);
    });

    testWidgets(
      'Empty quantity in dialog shows validation error and does not crash',
      (tester) async {
        final fakeProductBloc = FakeProductBloc(
          const ProductSuccess([productA]),
        );
        final fakeCartBloc = FakeCartBloc(const CartLoaded({1: 2}));

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<ProductBloc>.value(value: fakeProductBloc),
                BlocProvider<CartBloc>.value(value: fakeCartBloc),
              ],
              child: const CartScreen(),
            ),
          ),
        );

        // Tap quantity to edit
        await tester.tap(
          find.byKey(const ValueKey('cart_item_quantity_tap_1')),
        );
        await tester.pumpAndSettle();

        // Clear text completely
        await tester.enterText(
          find.byKey(const ValueKey('quantity_input_field')),
          '',
        );
        await tester.tap(find.byKey(const ValueKey('quantity_submit_button')));
        await tester.pumpAndSettle();

        // Validation error shown
        expect(find.text('Please enter a quantity'), findsOneWidget);

        // Cancel dialog
        await tester.tap(find.byKey(const ValueKey('quantity_cancel_button')));
        await tester.pumpAndSettle();

        // Quantity remains 2
        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets('Very large quantity in dialog shows validation error', (
      tester,
    ) async {
      final fakeProductBloc = FakeProductBloc(const ProductSuccess([productA]));
      final fakeCartBloc = FakeCartBloc(const CartLoaded({1: 2}));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ProductBloc>.value(value: fakeProductBloc),
              BlocProvider<CartBloc>.value(value: fakeCartBloc),
            ],
            child: const CartScreen(),
          ),
        ),
      );

      // Tap quantity to edit
      await tester.tap(find.byKey(const ValueKey('cart_item_quantity_tap_1')));
      await tester.pumpAndSettle();

      // Enter large number
      await tester.enterText(
        find.byKey(const ValueKey('quantity_input_field')),
        '999999',
      );
      await tester.tap(find.byKey(const ValueKey('quantity_submit_button')));
      await tester.pumpAndSettle();

      // Validation error shown
      expect(find.text('Maximum quantity is 9999'), findsOneWidget);
    });
  });

  group('Full Persistence Lifecycle (Hive Box Restart)', () {
    late Directory tempDir;
    late Box productsBox;
    late Box cartBox;
    late LocalDatabase localDb;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cart_persistence_test_');
      Hive.init(tempDir.path);
      productsBox = await Hive.openBox(LocalDatabase.productsBoxName);
      cartBox = await Hive.openBox(LocalDatabase.cartBoxName);
      localDb = LocalDatabase(productsBox: productsBox, cartBox: cartBox);
    });

    tearDown(() async {
      if (productsBox.isOpen) {
        await productsBox.close();
      }
      if (cartBox.isOpen) {
        await cartBox.close();
      }
      await Hive.close();
      if (tempDir.existsSync()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    test('Full user lifecycle: Add products -> change quantities -> kill app -> restart -> cart restored exactly', () async {
      // 1. Initial Launch: Empty cart
      var cartBloc = CartBloc(localDatabase: localDb);
      cartBloc.add(const LoadCart());
      await Future.delayed(const Duration(milliseconds: 20));
      expect(cartBloc.state.quantities, isEmpty);

      // 2. Add Product 101, 102
      cartBloc.add(const AddToCart(101));
      cartBloc.add(const AddToCart(102));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(cartBloc.state.getQuantity(101), 1);
      expect(cartBloc.state.getQuantity(102), 1);
      expect(cartBloc.state.uniqueItems, 2);
      expect(cartBloc.state.totalQuantity, 2);

      // 3. Update quantity of 101 to 5, 102 to 3
      cartBloc.add(const UpdateQuantity(productId: 101, quantity: 5));
      cartBloc.add(const UpdateQuantity(productId: 102, quantity: 3));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(cartBloc.state.getQuantity(101), 5);
      expect(cartBloc.state.getQuantity(102), 3);
      expect(cartBloc.state.uniqueItems, 2);
      expect(cartBloc.state.totalQuantity, 8);

      // 4. Completely terminate app (close Bloc and Hive boxes)
      await cartBloc.close();
      await productsBox.close();
      await cartBox.close();

      // 5. Restart app: Reopen boxes and instantiate new CartBloc
      final reopenedProductsBox = await Hive.openBox(
        LocalDatabase.productsBoxName,
      );
      final reopenedCartBox = await Hive.openBox(LocalDatabase.cartBoxName);
      final reopenedDb = LocalDatabase(
        productsBox: reopenedProductsBox,
        cartBox: reopenedCartBox,
      );

      final restartedCartBloc = CartBloc(localDatabase: reopenedDb);
      restartedCartBloc.add(const LoadCart());
      await Future.delayed(const Duration(milliseconds: 20));

      // 6. Verify cart restored exactly!
      expect(restartedCartBloc.state.getQuantity(101), 5);
      expect(restartedCartBloc.state.getQuantity(102), 3);
      expect(restartedCartBloc.state.uniqueItems, 2);
      expect(restartedCartBloc.state.totalQuantity, 8);

      await restartedCartBloc.close();
      await reopenedProductsBox.close();
      await reopenedCartBox.close();
    });
  });
}
