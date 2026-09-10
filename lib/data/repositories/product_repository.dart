import '../datasources/local_database.dart';
import '../datasources/product_api_service.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ProductApiService _apiService;
  final LocalDatabase _localDatabase;

  ProductRepository({
    ProductApiService? apiService,
    LocalDatabase? localDatabase,
  }) : _apiService = apiService ?? ProductApiService(),
       _localDatabase = localDatabase ?? LocalDatabase();

  /// Checks local product cache and returns cached products.
  List<ProductModel> getCachedProducts() {
    return _localDatabase.getCachedProducts();
  }

  /// Checks whether local product cache contains products.
  bool get hasCachedProducts => _localDatabase.hasCachedProducts;

  /// Fetches fresh products from the API.
  /// When successfully fetched, saves them to Hive.
  /// If API fetching fails and cached products exist, returns cached products.
  Future<List<ProductModel>> fetchFreshProducts() async {
    try {
      final freshProducts = await _apiService.fetchProducts();
      await _localDatabase.saveProducts(freshProducts);
      return freshProducts;
    } catch (error) {
      final cached = _localDatabase.getCachedProducts();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  /// Product loading coordinator:
  /// 1. Checks local cache first (unless [forceRefresh] is true).
  /// 2. If cached products exist, returns them immediately.
  /// 3. Otherwise, fetches fresh products from the API and caches them.
  /// 4. If API fails and cached data exists, falls back to cache.
  Future<List<ProductModel>> getProducts({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _localDatabase.getCachedProducts();
      if (cached.isNotEmpty) {
        return cached;
      }
    }
    return fetchFreshProducts();
  }
}
