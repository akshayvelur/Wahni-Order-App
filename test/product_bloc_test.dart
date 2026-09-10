import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wahniorderapp/bloc/product/product_bloc.dart';
import 'package:wahniorderapp/bloc/product/product_event.dart';
import 'package:wahniorderapp/bloc/product/product_state.dart';
import 'package:wahniorderapp/core/constants/api_constants.dart';
import 'package:wahniorderapp/data/datasources/local_database.dart';
import 'package:wahniorderapp/data/datasources/product_api_service.dart';
import 'package:wahniorderapp/data/models/product_model.dart';
import 'package:wahniorderapp/data/repositories/product_repository.dart';

void main() {
  late Directory tempDir;
  late Box productsBox;
  late Box cartBox;
  late LocalDatabase localDatabase;

  final sampleProducts = [
    const ProductModel(
      id: 1,
      title: 'Cached Bag',
      price: 50.0,
      image: 'https://example.com/bag.png',
    ),
  ];

  final freshProducts = [
    const ProductModel(
      id: 1,
      title: 'Fresh Bag',
      price: 55.0,
      image: 'https://example.com/bag.png',
    ),
    const ProductModel(
      id: 2,
      title: 'Fresh Shoes',
      price: 80.0,
      image: 'https://example.com/shoes.png',
    ),
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('product_bloc_test_');
    Hive.init(tempDir.path);
    productsBox = await Hive.openBox(LocalDatabase.productsBoxName);
    cartBox = await Hive.openBox(LocalDatabase.cartBoxName);
    localDatabase = LocalDatabase(productsBox: productsBox, cartBox: cartBox);
  });

  tearDown(() async {
    await productsBox.close();
    await cartBox.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  ProductRepository createRepository({required http.Client client}) {
    final apiService = ProductApiService(client: client);
    return ProductRepository(
      apiService: apiService,
      localDatabase: localDatabase,
    );
  }

  group('ProductBloc', () {
    test('initial state is ProductInitial', () {
      final repository = createRepository(
        client: MockClient((request) async => http.Response('[]', 200)),
      );
      final bloc = ProductBloc(repository: repository);
      expect(bloc.state, const ProductInitial());
      bloc.close();
    });

    test('LoadProducts emits [ProductLoading, ProductSuccess] when no cache exists and API succeeds', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == ApiConstants.productsUrl) {
          return http.Response('''[
              {"id": 1, "title": "Fresh Bag", "price": 55.0, "image": "https://example.com/bag.png"},
              {"id": 2, "title": "Fresh Shoes", "price": 80.0, "image": "https://example.com/shoes.png"}
            ]''', 200);
        }
        return http.Response('Not found', 404);
      });

      final repository = createRepository(client: mockClient);
      final bloc = ProductBloc(repository: repository);

      expectLater(
        bloc.stream,
        emitsInOrder([const ProductLoading(), ProductSuccess(freshProducts)]),
      );

      bloc.add(const LoadProducts());
      await untilCalled(mockClient);
      await bloc.close();
    });

    test('LoadProducts emits cached products immediately, then emits fresh products from API', () async {
      // Pre-populate cache
      await localDatabase.saveProducts(sampleProducts);

      final mockClient = MockClient((request) async {
        return http.Response('''[
            {"id": 1, "title": "Fresh Bag", "price": 55.0, "image": "https://example.com/bag.png"},
            {"id": 2, "title": "Fresh Shoes", "price": 80.0, "image": "https://example.com/shoes.png"}
          ]''', 200);
      });

      final repository = createRepository(client: mockClient);
      final bloc = ProductBloc(repository: repository);

      expectLater(
        bloc.stream,
        emitsInOrder([
          ProductSuccess(sampleProducts),
          ProductSuccess(freshProducts),
        ]),
      );

      bloc.add(const LoadProducts());
      await untilCalled(mockClient);
      await bloc.close();
    });

    test(
      'LoadProducts keeps cached products when API fails and cache exists',
      () async {
        // Pre-populate cache
        await localDatabase.saveProducts(sampleProducts);

        final mockClient = MockClient((request) async {
          return http.Response('Server Error', 500);
        });

        final repository = createRepository(client: mockClient);
        final bloc = ProductBloc(repository: repository);

        // Should emit ProductSuccess with cached products and NOT emit ProductFailure
        expectLater(
          bloc.stream,
          emitsInOrder([ProductSuccess(sampleProducts)]),
        );

        bloc.add(const LoadProducts());
        await untilCalled(mockClient);
        await bloc.close();
      },
    );

    test('LoadProducts emits [ProductLoading, ProductFailure] when no cache and API fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final repository = createRepository(client: mockClient);
      final bloc = ProductBloc(repository: repository);

      expectLater(
        bloc.stream,
        emitsInOrder([const ProductLoading(), isA<ProductFailure>()]),
      );

      bloc.add(const LoadProducts());
      await untilCalled(mockClient);
      await bloc.close();
    });

    test('RefreshProducts updates products without emitting ProductLoading when products are already displayed', () async {
      await localDatabase.saveProducts(sampleProducts);

      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('''[
            {"id": 1, "title": "Fresh Bag", "price": 55.0, "image": "https://example.com/bag.png"},
            {"id": 2, "title": "Fresh Shoes", "price": 80.0, "image": "https://example.com/shoes.png"}
          ]''', 200);
        } else {
          return http.Response('''[
            {"id": 1, "title": "Updated Bag", "price": 60.0, "image": "https://example.com/bag.png"}
          ]''', 200);
        }
      });

      final repository = createRepository(client: mockClient);
      final bloc = ProductBloc(repository: repository);

      // First load products
      bloc.add(const LoadProducts());
      await untilCalled(mockClient);

      // Now refresh with updated items: should emit updated ProductSuccess and NOT ProductLoading
      final updatedProducts = [
        const ProductModel(
          id: 1,
          title: 'Updated Bag',
          price: 60.0,
          image: 'https://example.com/bag.png',
        ),
      ];

      expectLater(bloc.stream, emits(ProductSuccess(updatedProducts)));

      bloc.add(const RefreshProducts());
      await untilCalled(mockClient);
      await bloc.close();
    });

    test(
      'RetryProducts attempts reload and emits ProductSuccess on success',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('''[
            {"id": 1, "title": "Fresh Bag", "price": 55.0, "image": "https://example.com/bag.png"},
            {"id": 2, "title": "Fresh Shoes", "price": 80.0, "image": "https://example.com/shoes.png"}
          ]''', 200);
        });

        final repository = createRepository(client: mockClient);
        final bloc = ProductBloc(repository: repository);

        expectLater(
          bloc.stream,
          emitsInOrder([const ProductLoading(), ProductSuccess(freshProducts)]),
        );

        bloc.add(const RetryProducts());
        await untilCalled(mockClient);
        await bloc.close();
      },
    );
  });
}

Future<void> untilCalled(MockClient client) async {
  // Allow async events to settle
  await Future.delayed(const Duration(milliseconds: 50));
}
