import 'package:equatable/equatable.dart';

class CartState extends Equatable {
  /// Map of productId -> quantity.
  final Map<int, int> quantities;

  const CartState({this.quantities = const {}});

  /// The number of distinct products in the cart.
  /// Does not sum the quantities of each item.
  /// (e.g. A=5, B=2, C=1 -> uniqueItems = 3).
  int get uniqueItems => quantities.length;

  /// The total quantity of all items across all products in the cart.
  /// (e.g. A=5, B=2, C=1 -> totalQuantity = 8).
  int get totalQuantity =>
      quantities.values.fold(0, (sum, quantity) => sum + quantity);

  /// Helper to get the quantity of a specific product.
  int getQuantity(int productId) => quantities[productId] ?? 0;

  /// Helper to check whether a specific product is currently in the cart.
  bool containsProduct(int productId) => (quantities[productId] ?? 0) > 0;

  CartState copyWith({Map<int, int>? quantities}) {
    return CartState(quantities: quantities ?? this.quantities);
  }

  @override
  List<Object?> get props => [quantities];
}

/// Initial state before cart data has been loaded from Hive.
class CartInitial extends CartState {
  const CartInitial() : super(quantities: const {});
}

/// State emitted when cart data is active and synchronized with Hive.
class CartLoaded extends CartState {
  const CartLoaded(Map<int, int> quantities) : super(quantities: quantities);
}
