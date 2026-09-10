import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
      title: 'Backpack',
      price: 109.95,
      image: 'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg',
    ),
    const ProductModel(
      id: 2,
      title: 'T-Shirt',
      price: 22.3,
      image: 'https://fakestoreapi.com/img/71-3HjGNDUL._AC_SY879._SX._UX._SY._UY_.jpg',
    ),
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
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

  group('LocalDatabase - Hive Persistence', () {
    test('initializes and verifies boxes are open', () {
      expect(localDatabase.productsBox.isOpen, isTrue);
      expect(localDatabase.cartBox.isOpen, isTrue);
    });

    test('saves and retrieves products correctly', () async {
      expect(localDatabase.hasCachedProducts, isFalse);
      expect(localDatabase.getCachedProducts(), isEmpty);

      await localDatabase.saveProducts(sampleProducts);

      expect(localDatabase.hasCachedProducts, isTrue);
      final cached = localDatabase.getCachedProducts();
      expect(cached.length, 2);
      expect(cached[0].id, 1);
      expect(cached[0].title, 'Backpack');
      expect(cached[0].price, 109.95);
      expect(
        cached[0].image,
        'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg',
      );
      expect(cached[1].id, 2);
      expect(cached[1].title, 'T-Shirt');
      expect(cached[1].price, 22.3);
    });

    test(
      'cached product data survives simulated restart (box close and reopen)',
      () async {
        await localDatabase.saveProducts(sampleProducts);

        // Simulate app termination by closing boxes
        await productsBox.close();

        // Simulate app restart by reopening the box from the same directory
        final reopenedProductsBox = await Hive.openBox(
          LocalDatabase.productsBoxName,
        );
        final restoredDb = LocalDatabase(
          productsBox: reopenedProductsBox,
          cartBox: cartBox,
        );

        final cached = restoredDb.getCachedProducts();
        expect(cached.length, 2);
        expect(cached[0], sampleProducts[0]);
        expect(cached[1], sampleProducts[1]);

        await reopenedProductsBox.close();
        // Re-open for tearDown
        productsBox = await Hive.openBox(LocalDatabase.productsBoxName);
      },
    );

    test(
      'persists cart quantities (productId and quantity only, no totals)',
      () async {
        // Save cart quantities
        await localDatabase.saveCartQuantity(1, 3);
        await localDatabase.saveCartQuantity(2, 1);

        expect(localDatabase.getCartQuantity(1), 3);
        expect(localDatabase.getCartQuantity(2), 1);
        expect(localDatabase.getCartQuantity(99), 0);

        final allQuantities = localDatabase.getCartQuantities();
        expect(allQuantities, {1: 3, 2: 1});

        // Updating to 0 removes the item
        await localDatabase.saveCartQuantity(2, 0);
        expect(localDatabase.getCartQuantity(2), 0);
        expect(localDatabase.getCartQuantities(), {1: 3});

        // Remove specific item
        await localDatabase.removeCartItem(1);
        expect(localDatabase.getCartQuantities(), isEmpty);
      },
    );
  });

  group('ProductRepository', () {
    test(
      'returns cached products when available without calling API',
      () async {
        await localDatabase.saveProducts(sampleProducts);

        // Client throws if called
        final mockClient = MockClient((request) async {
          throw Exception('API should not be called');
        });
        final apiService = ProductApiService(client: mockClient);
        final repository = ProductRepository(
          apiService: apiService,
          localDatabase: localDatabase,
        );

        final products = await repository.getProducts();

        expect(products.length, 2);
        expect(products, sampleProducts);
      },
    );

    test(
      'fetches fresh products from API and saves to Hive when cache is empty',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.toString() == ApiConstants.productsUrl) {
            return http.Response('''[
              {"id": 10, "title": "Fresh Item", "price": 49.99, "image": "https://example.com/fresh.png"}
            ]''', 200);
          }
          return http.Response('Not found', 404);
        });
        final apiService = ProductApiService(client: mockClient);
        final repository = ProductRepository(
          apiService: apiService,
          localDatabase: localDatabase,
        );

        expect(localDatabase.hasCachedProducts, isFalse);

        final products = await repository.getProducts();

        expect(products.length, 1);
        expect(products.first.title, 'Fresh Item');

        // Verify it was saved to Hive
        expect(localDatabase.hasCachedProducts, isTrue);
        expect(localDatabase.getCachedProducts().first.title, 'Fresh Item');
      },
    );

    test('falls back to cached products if API fetch fails', () async {
      // Pre-seed cache
      await localDatabase.saveProducts(sampleProducts);

      // Failing API client
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final apiService = ProductApiService(client: mockClient);
      final repository = ProductRepository(
        apiService: apiService,
        localDatabase: localDatabase,
      );

      // Force refresh fails against API, but fallback returns cached items
      final products = await repository.fetchFreshProducts();

      expect(products.length, 2);
      expect(products[0].title, 'Backpack');
      expect(products[1].title, 'T-Shirt');
    });

    test('rethrows error when API fails and NO cache exists', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Bad Request', 400);
      });
      final apiService = ProductApiService(client: mockClient);
      final repository = ProductRepository(
        apiService: apiService,
        localDatabase: localDatabase,
      );

      expect(localDatabase.hasCachedProducts, isFalse);

      expect(
        () => repository.fetchFreshProducts(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
