import 'package:hive_flutter/hive_flutter.dart';

import '../models/product_model.dart';

class LocalDatabase {
  static const String productsBoxName = 'products_box';
  static const String cartBoxName = 'cart_box';

  final Box _productsBox;
  final Box _cartBox;

  LocalDatabase({Box? productsBox, Box? cartBox})
    : _productsBox = productsBox ?? Hive.box(productsBoxName),
      _cartBox = cartBox ?? Hive.box(cartBoxName);

  Box get productsBox => _productsBox;
  Box get cartBox => _cartBox;

  /// Initializes Hive and opens the boxes for products and cart quantities.
  static Future<LocalDatabase> init([String? subDir]) async {
    await Hive.initFlutter(subDir);
    final productsBox = await Hive.openBox(productsBoxName);
    final cartBox = await Hive.openBox(cartBoxName);
    return LocalDatabase(productsBox: productsBox, cartBox: cartBox);
  }

  // --------------------------------------------------------------------------
  // Product Cache Operations
  // --------------------------------------------------------------------------

  /// Saves products to local Hive cache.
  /// Persists: id, title, price, image.
  Future<void> saveProducts(List<ProductModel> products) async {
    await _productsBox.clear();
    final Map<int, Map<String, dynamic>> entries = {
      for (final product in products) product.id: product.toMap(),
    };
    await _productsBox.putAll(entries);
  }

  /// Retrieves cached products from Hive.
  List<ProductModel> getCachedProducts() {
    if (_productsBox.isEmpty) {
      return [];
    }
    return _productsBox.values.map<ProductModel>((item) {
      return ProductModel.fromMap(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  /// Whether there are any products currently cached.
  bool get hasCachedProducts => _productsBox.isNotEmpty;

  /// Clears cached products.
  Future<void> clearProducts() async {
    await _productsBox.clear();
  }

  // --------------------------------------------------------------------------
  // Cart Quantity Operations
  // Persists only: productId and quantity.
  // Calculated subtotal and grand total are NOT persisted.
  // --------------------------------------------------------------------------

  /// Saves or updates the quantity for a product in the cart.
  /// If quantity <= 0, the item is removed from the cart.
  Future<void> saveCartQuantity(int productId, int quantity) async {
    if (quantity <= 0) {
      await _cartBox.delete(productId);
    } else {
      await _cartBox.put(productId, quantity);
    }
  }

  /// Gets the quantity of a specific product in the cart.
  int getCartQuantity(int productId) {
    return (_cartBox.get(productId) as int?) ?? 0;
  }

  /// Retrieves all cart items as a map of productId -> quantity.
  Map<int, int> getCartQuantities() {
    final Map<int, int> result = {};
    for (final key in _cartBox.keys) {
      final value = _cartBox.get(key);
      if (key is int && value is int) {
        result[key] = value;
      }
    }
    return result;
  }

  /// Removes an item from the cart.
  Future<void> removeCartItem(int productId) async {
    await _cartBox.delete(productId);
  }

  /// Clears all cart items.
  Future<void> clearCart() async {
    await _cartBox.clear();
  }
}
