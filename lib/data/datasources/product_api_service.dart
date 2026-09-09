import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/product_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ProductApiService {
  final http.Client _client;

  ProductApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ProductModel>> fetchProducts() async {
    final http.Response response;
    try {
      response = await _client.get(Uri.parse(ApiConstants.productsUrl));
    } on http.ClientException catch (e) {
      throw ApiException('Network error occurred: ${e.message}');
    } catch (e) {
      throw ApiException('Failed to connect to the server: $e');
    }

    if (response.statusCode != 200) {
      throw ApiException(
        'Server returned an error status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final dynamic decodedBody;
    try {
      decodedBody = jsonDecode(response.body);
    } catch (e) {
      throw const ApiException(
        'Malformed response: Unable to parse JSON response.',
      );
    }

    if (decodedBody is! List) {
      throw ApiException(
        'Invalid response format: Expected a JSON array but received ${decodedBody.runtimeType}.',
      );
    }

    try {
      return decodedBody.map<ProductModel>((item) {
        if (item is! Map<String, dynamic>) {
          if (item is Map) {
            return ProductModel.fromJson(Map<String, dynamic>.from(item));
          }
          throw const ApiException(
            'Invalid product format: Each item in the array must be a JSON object.',
          );
        }
        return ProductModel.fromJson(item);
      }).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to parse product data: $e');
    }
  }
}
