import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wahniorderapp/core/constants/api_constants.dart';
import 'package:wahniorderapp/data/datasources/product_api_service.dart';
import 'package:wahniorderapp/data/models/product_model.dart';

void main() {
  group('ProductModel', () {
    test('parses correctly when price is a double', () {
      final json = {
        'id': 1,
        'title': 'Test Item',
        'price': 19.99,
        'image': 'https://example.com/item.png',
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 1);
      expect(product.title, 'Test Item');
      expect(product.price, 19.99);
      expect(product.image, 'https://example.com/item.png');
    });

    test(
      'parses correctly when price is an int (num to double conversion)',
      () {
        final json = {
          'id': 2,
          'title': 'Hard Drive',
          'price': 64, // int from API
          'image': 'https://example.com/disk.png',
        };

        final product = ProductModel.fromJson(json);

        expect(product.id, 2);
        expect(product.price, 64.0);
        expect(product.price, isA<double>());
      },
    );

    test('handles missing or null values gracefully', () {
      final json = <String, dynamic>{
        'id': null,
        'title': null,
        'price': null,
        'image': null,
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 0);
      expect(product.title, '');
      expect(product.price, 0.0);
      expect(product.image, '');
    });

    test('toMap converts ProductModel back to map correctly', () {
      const product = ProductModel(
        id: 5,
        title: 'Shirt',
        price: 25.5,
        image: 'https://example.com/shirt.png',
      );

      final map = product.toMap();

      expect(map, {
        'id': 5,
        'title': 'Shirt',
        'price': 25.5,
        'image': 'https://example.com/shirt.png',
      });
    });
  });

  group('ProductApiService', () {
    test(
      'fetches and returns a list of ProductModel on 200 response',
      () async {
        final mockResponse = jsonEncode([
          {
            'id': 1,
            'title': 'Product A',
            'price': 10.5,
            'image': 'https://example.com/a.png',
          },
          {
            'id': 2,
            'title': 'Product B',
            'price': 50, // int
            'image': 'https://example.com/b.png',
          },
        ]);

        final mockClient = MockClient((request) async {
          if (request.url.toString() == ApiConstants.productsUrl) {
            return http.Response(mockResponse, 200);
          }
          return http.Response('Not Found', 404);
        });

        final service = ProductApiService(client: mockClient);
        final products = await service.fetchProducts();

        expect(products.length, 2);
        expect(products[0].title, 'Product A');
        expect(products[0].price, 10.5);
        expect(products[1].title, 'Product B');
        expect(products[1].price, 50.0);
      },
    );

    test('throws ApiException when status code is not 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ProductApiService(client: mockClient);

      expect(
        () => service.fetchProducts(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('throws ApiException when response is not a JSON array', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Not an array'}), 200);
      });

      final service = ProductApiService(client: mockClient);

      expect(
        () => service.fetchProducts(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Expected a JSON array'),
          ),
        ),
      );
    });

    test('throws ApiException on malformed JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('not valid json {', 200);
      });

      final service = ProductApiService(client: mockClient);

      expect(
        () => service.fetchProducts(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Unable to parse JSON response'),
          ),
        ),
      );
    });

    test('throws ApiException when array contains invalid item type', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(['not an object']), 200);
      });

      final service = ProductApiService(client: mockClient);

      expect(
        () => service.fetchProducts(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Each item in the array must be a JSON object'),
          ),
        ),
      );
    });

    test('live endpoint returns products (if network is available)', () async {
      final liveService = ProductApiService();
      try {
        final products = await liveService.fetchProducts();
        expect(products, isNotEmpty);
        expect(products.first.id, isPositive);
        expect(products.first.title, isNotEmpty);
      } catch (e) {
        // In case network is restricted in certain environments
        expect(e, isA<ApiException>());
      }
    });
  });
}
