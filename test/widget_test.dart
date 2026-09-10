import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wahniorderapp/bloc/product/product_bloc.dart';
import 'package:wahniorderapp/bloc/product/product_event.dart';
import 'package:wahniorderapp/bloc/product/product_state.dart';
import 'package:wahniorderapp/data/models/product_model.dart';
import 'package:wahniorderapp/screens/product_list/product_list_screen.dart';
import 'package:wahniorderapp/widgets/product_card.dart';

class FakeProductBloc extends Bloc<ProductEvent, ProductState>
    implements ProductBloc {
  FakeProductBloc(super.initialState);
}

void main() {
  const testProduct = ProductModel(
    id: 1,
    title: 'Fjallraven Backpack',
    price: 109.95,
    image: 'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg',
  );

  group('ProductCard Widget', () {
    testWidgets('renders title, price, and placeholder Add to Cart button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProductCard(product: testProduct)),
        ),
      );

      expect(find.text('Fjallraven Backpack'), findsOneWidget);
      expect(find.text('₹109.95'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
    });
  });

  group('ProductListScreen Widget', () {
    testWidgets(
      'renders AppBar with Wahni Products title and loading indicator on ProductLoading',
      (tester) async {
        final fakeBloc = FakeProductBloc(const ProductLoading());

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ProductBloc>.value(
              value: fakeBloc,
              child: const ProductListScreen(),
            ),
          ),
        );

        expect(find.text('Wahni Products'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await fakeBloc.close();
      },
    );

    testWidgets('renders products in responsive GridView on ProductSuccess', (
      tester,
    ) async {
      final fakeBloc = FakeProductBloc(const ProductSuccess([testProduct]));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProductBloc>.value(
            value: fakeBloc,
            child: const ProductListScreen(),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Fjallraven Backpack'), findsOneWidget);
      expect(find.text('₹109.95'), findsOneWidget);
      expect(find.byType(ProductCard), findsOneWidget);

      await fakeBloc.close();
    });

    testWidgets('renders error state and retry button on ProductFailure', (
      tester,
    ) async {
      final fakeBloc = FakeProductBloc(
        const ProductFailure('Failed to connect'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ProductBloc>.value(
            value: fakeBloc,
            child: const ProductListScreen(),
          ),
        ),
      );

      expect(find.text('Failed to load products'), findsOneWidget);
      expect(find.text('Failed to connect'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await fakeBloc.close();
    });

    testWidgets(
      'renders empty message when ProductSuccess has empty product list',
      (tester) async {
        final fakeBloc = FakeProductBloc(const ProductSuccess([]));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ProductBloc>.value(
              value: fakeBloc,
              child: const ProductListScreen(),
            ),
          ),
        );

        expect(
          find.text('No products available at the moment.'),
          findsOneWidget,
        );
        expect(find.text('Refresh'), findsOneWidget);

        await fakeBloc.close();
      },
    );
  });
}
