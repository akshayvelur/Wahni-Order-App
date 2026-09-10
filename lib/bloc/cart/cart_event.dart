import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Restores saved cart quantities from Hive when the application starts.
class LoadCart extends CartEvent {
  const LoadCart();
}

/// Adds a product to the cart or increments its existing quantity.
class AddToCart extends CartEvent {
  final int productId;

  const AddToCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Updates the quantity of a product in the cart.
/// Positive values update the quantity, while zero or negative values remove it.
class UpdateQuantity extends CartEvent {
  final int productId;
  final int quantity;

  const UpdateQuantity({required this.productId, required this.quantity});

  @override
  List<Object?> get props => [productId, quantity];
}

/// Removes a product entirely from the in-memory state and Hive.
class RemoveFromCart extends CartEvent {
  final int productId;

  const RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}
