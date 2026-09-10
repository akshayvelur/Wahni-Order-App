import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wahniorderapp/bloc/cart/cart_bloc.dart';
import 'package:wahniorderapp/bloc/cart/cart_event.dart';
import 'package:wahniorderapp/bloc/cart/cart_state.dart';
import 'package:wahniorderapp/bloc/product/product_bloc.dart';
import 'package:wahniorderapp/bloc/product/product_event.dart';
import 'package:wahniorderapp/bloc/product/product_state.dart';
import 'package:wahniorderapp/core/constants/app_constants.dart';
import 'package:wahniorderapp/data/models/product_model.dart';
import 'package:wahniorderapp/screens/cart/cart_screen.dart';
import 'package:wahniorderapp/screens/main_screen.dart';
import 'package:wahniorderapp/widgets/cart_item_tile.dart';
import 'package:wahniorderapp/widgets/cart_summary.dart';

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
        updated[event.productId] = event.quantity;
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
      updated[event.productId] = (updated[event.productId] ?? 0) + 1;
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

  group('CartItemTile Widget', () {
    testWidgets(
      'displays product image, name, unit price, quantity, and subtotal',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: CartItemTile(product: productA, quantity: 3)),
          ),
        );

        // Verify Product name
        expect(find.text('Product A'), findsOneWidget);

        // Verify Unit price
        expect(
          find.text('Unit Price: ${AppConstants.currencySymbol}10.00'),
          findsOneWidget,
        );

        // Verify Current quantity
        expect(find.text('3'), findsOneWidget);

        // Verify Subtotal: 10.0 × 3 = 30.00
        expect(
          find.text('Subtotal: ${AppConstants.currencySymbol}30.00'),
          findsOneWidget,
        );

        // Verify [-] and [+] icons exist
        expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      },
    );

    testWidgets('increment and decrement callbacks fire correctly', (
      tester,
    ) async {
      bool incrementCalled = false;
      bool decrementCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemTile(
              product: productA,
              quantity: 3,
              onIncrement: () => incrementCalled = true,
              onDecrement: () => decrementCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('cart_item_increment_1')));
      expect(incrementCalled, isTrue);

      await tester.tap(find.byKey(const ValueKey('cart_item_decrement_1')));
      expect(decrementCalled, isTrue);
    });
  });

  group('CartSummary Widget', () {
    testWidgets('displays Unique Items, Total Units, and Grand Total', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CartSummary(uniqueItems: 2, totalUnits: 5, grandTotal: 70.0),
          ),
        ),
      );

      expect(find.text('2 unique items in cart'), findsOneWidget);
      expect(find.text('Total Units: 5'), findsOneWidget);
      expect(find.text('${AppConstants.currencySymbol}70.00'), findsOneWidget);
      expect(find.text('Proceed to Checkout'), findsOneWidget);
    });
  });

  group('CartScreen Empty State', () {
    testWidgets('displays empty cart message and Continue Shopping button', (
      tester,
    ) async {
      bool continueShoppingTapped = false;
      final fakeCartBloc = FakeCartBloc(const CartInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CartBloc>.value(
            value: fakeCartBloc,
            child: CartScreen(
              onContinueShopping: () => continueShoppingTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(
        find.text('Add some products to continue shopping.'),
        findsOneWidget,
      );
      expect(find.text('Continue Shopping'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('continue_shopping_button')));
      expect(continueShoppingTapped, isTrue);
    });
  });

  group('Prompt Calculation & Synchronization Verification', () {
    testWidgets(
      'Verification test: Product A (10 x 3 = 30) & Product B (20 x 2 = 40) => Unique: 2, Units: 5, Grand Total: 70',
      (tester) async {
        final fakeProductBloc = FakeProductBloc(
          const ProductSuccess([productA, productB]),
        );
        final fakeCartBloc = FakeCartBloc(const CartLoaded({1: 3, 2: 2}));

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

        // Verify Product A items & subtotal
        expect(find.text('Product A'), findsOneWidget);
        expect(
          find.text('Subtotal: ${AppConstants.currencySymbol}30.00'),
          findsOneWidget,
        );

        // Verify Product B items & subtotal
        expect(find.text('Product B'), findsOneWidget);
        expect(
          find.text('Subtotal: ${AppConstants.currencySymbol}40.00'),
          findsOneWidget,
        );

        // Verify CartSummary calculations:
        // Unique Items = 2
        expect(find.text('2 unique items in cart'), findsOneWidget);
        // Total Units = 3 + 2 = 5
        expect(find.text('Total Units: 5'), findsOneWidget);
        // Grand Total = 30 + 40 = 70.00
        expect(
          find.text('${AppConstants.currencySymbol}70.00'),
          findsOneWidget,
        );

        // Now test changing quantity from CartScreen:
        // Decrement Product B (from 2 to 1)
        await tester.tap(find.byKey(const ValueKey('cart_item_decrement_2')));
        await tester.pump();

        // Total Units should now be 3 + 1 = 4
        expect(find.text('Total Units: 4'), findsOneWidget);
        // Grand Total should now be 30 + 20 = 50.00
        expect(
          find.text('${AppConstants.currencySymbol}50.00'),
          findsOneWidget,
        );

        // Decrement Product B again (from 1 to 0 => removed)
        await tester.tap(find.byKey(const ValueKey('cart_item_decrement_2')));
        await tester.pump();

        // Product B should be completely removed from screen
        expect(find.text('Product B'), findsNothing);
        // Unique items is now 1
        expect(find.text('1 unique items in cart'), findsOneWidget);
        // Total Units is now 3
        expect(find.text('Total Units: 3'), findsOneWidget);
        // Grand Total is now 30.00
        expect(find.text('${AppConstants.currencySymbol}30.00'), findsWidgets);
      },
    );

    testWidgets(
      'Product Listing and Cart Screen stay synchronized automatically',
      (tester) async {
        final fakeProductBloc = FakeProductBloc(
          const ProductSuccess([productA, productB]),
        );
        final fakeCartBloc = FakeCartBloc(const CartLoaded({1: 1}));

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

        // On Product Listing tab:
        // Product A has 1 in cart, so badge '1 in cart' is visible and button shows 'Add More (1)'
        expect(
          find.byKey(const ValueKey('product_in_cart_badge_1')),
          findsOneWidget,
        );
        expect(find.text('Add More (1)'), findsOneWidget);

        // Product B is not in cart
        expect(
          find.byKey(const ValueKey('product_in_cart_badge_2')),
          findsNothing,
        );
        expect(find.text('Add to Cart'), findsOneWidget);

        // Switch to Cart tab
        await tester.tap(find.text('Cart'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Decrement Product A to 0
        await tester.tap(find.byKey(const ValueKey('cart_item_decrement_1')));
        await tester.pump();

        // Cart is now empty!
        expect(find.text('Your cart is empty'), findsOneWidget);

        // Tap 'Continue Shopping' to return to Product Listing
        await tester.tap(
          find.byKey(const ValueKey('continue_shopping_button')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // On Product Listing tab:
        // Product A in-cart badge is GONE, button is back to 'Add to Cart'
        expect(
          find.byKey(const ValueKey('product_in_cart_badge_1')),
          findsNothing,
        );
        expect(find.text('Add to Cart'), findsNWidgets(2));
      },
    );
  });
}
