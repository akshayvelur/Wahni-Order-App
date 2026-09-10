import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/local_database.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  static const int maxQuantityPerProduct = 9999;

  final LocalDatabase _localDatabase;
  final Map<int, int> _quantities = {};

  CartBloc({LocalDatabase? localDatabase})
    : _localDatabase = localDatabase ?? LocalDatabase(),
      super(const CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
  }

  /// Restores cart quantities from Hive on startup.
  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    final savedQuantities = _localDatabase.getCartQuantities();
    _quantities.clear();
    for (final entry in savedQuantities.entries) {
      if (entry.value > 0) {
        final safeQty = entry.value > maxQuantityPerProduct
            ? maxQuantityPerProduct
            : entry.value;
        _quantities[entry.key] = safeQty;
      }
    }
    emit(CartLoaded(Map<int, int>.from(_quantities)));
  }

  /// Handles adding a product to cart.
  /// If not in cart, quantity becomes 1.
  /// If already in cart, increments by 1 (clamped to maxQuantityPerProduct).
  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    final currentQty = _quantities[event.productId] ?? 0;
    final newQty = currentQty > 0
        ? (currentQty < maxQuantityPerProduct
              ? currentQty + 1
              : maxQuantityPerProduct)
        : 1;

    // 1. Update state synchronously
    _quantities[event.productId] = newQty;

    // 2. Persist to Hive
    await _localDatabase.saveCartQuantity(event.productId, newQty);

    // 3. Emit new state
    emit(CartLoaded(Map<int, int>.from(_quantities)));
  }

  /// Handles explicit quantity updates:
  /// Positive integer -> update quantity and persist (clamped to max).
  /// Zero or negative -> remove product from in-memory state and Hive.
  Future<void> _onUpdateQuantity(
    UpdateQuantity event,
    Emitter<CartState> emit,
  ) async {
    if (event.quantity > 0) {
      final safeQty = event.quantity > maxQuantityPerProduct
          ? maxQuantityPerProduct
          : event.quantity;

      // 1. Update state synchronously
      _quantities[event.productId] = safeQty;

      // 2. Persist to Hive
      await _localDatabase.saveCartQuantity(event.productId, safeQty);
    } else {
      // Zero or negative: remove product and never persist negative values
      // 1. Update state synchronously
      _quantities.remove(event.productId);

      // 2. Persist to Hive
      await _localDatabase.removeCartItem(event.productId);
    }

    // 3. Emit new state
    emit(CartLoaded(Map<int, int>.from(_quantities)));
  }

  /// Handles product removal from cart:
  /// Removes product from in-memory state and deletes from Hive.
  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    // 1. Update state synchronously
    _quantities.remove(event.productId);

    // 2. Persist to Hive
    await _localDatabase.removeCartItem(event.productId);

    // 3. Emit new state
    emit(CartLoaded(Map<int, int>.from(_quantities)));
  }
}
