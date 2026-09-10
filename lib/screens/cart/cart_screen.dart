import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../bloc/cart/cart_state.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_state.dart';
import '../../data/models/product_model.dart';
import '../../widgets/cart_item_tile.dart';
import '../../widgets/cart_summary.dart';

/// Cart Screen displaying:
/// - List of cart items ([CartItemTile]) with images, titles, unit prices,
///   quantities ([-] qty [+]), and subtotals.
/// - Sticky bottom [CartSummary] with unique items, total units, and dynamically
///   calculated grand total.
/// - Empty cart view with "Your cart is empty", "Add some products to continue shopping.",
///   and a "Continue Shopping" button returning to the product listing.
///
/// Uses existing [CartBloc] as single source of truth without local setState.
class CartScreen extends StatelessWidget {
  final VoidCallback? onContinueShopping;
  final VoidCallback? onBrowseProducts;

  const CartScreen({this.onContinueShopping, this.onBrowseProducts, super.key});

  VoidCallback? get _continueShoppingAction =>
      onContinueShopping ?? onBrowseProducts;

  void _handleContinueShopping(BuildContext context) {
    if (_continueShoppingAction != null) {
      _continueShoppingAction!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart'), centerTitle: true),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          // Empty cart state
          if (cartState.quantities.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove_shopping_cart_outlined,
                      size: 80,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      key: const ValueKey('empty_cart_title'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some products to continue shopping.',
                      key: const ValueKey('empty_cart_subtitle'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const ValueKey('continue_shopping_button'),
                      onPressed: () => _handleContinueShopping(context),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Continue Shopping'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Cart with items: retrieve product details from ProductBloc
          return BlocBuilder<ProductBloc, ProductState>(
            builder: (context, productState) {
              final List<ProductModel> products = productState is ProductSuccess
                  ? productState.products
                  : const [];

              final Map<int, ProductModel> productMap = {
                for (final p in products) p.id: p,
              };

              // Dynamically calculate Grand Total: sum(price * quantity)
              // Never persisted to Hive.
              double grandTotal = 0.0;
              for (final entry in cartState.quantities.entries) {
                final product = productMap[entry.key];
                if (product != null) {
                  grandTotal += product.price * entry.value;
                }
              }

              final cartProductIds = cartState.quantities.keys.toList();

              return Column(
                children: [
                  // Scrollable Cart Items List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartProductIds.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final productId = cartProductIds[index];
                        final quantity = cartState.getQuantity(productId);
                        final product = productMap[productId];

                        if (product == null) {
                          // Fallback placeholder if product is still loading or not in memory
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: ListTile(
                              title: Text('Product #$productId'),
                              subtitle: Text('Quantity: $quantity'),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  context.read<CartBloc>().add(
                                    RemoveFromCart(productId),
                                  );
                                },
                              ),
                            ),
                          );
                        }

                        return CartItemTile(
                          product: product,
                          quantity: quantity,
                          onIncrement: () {
                            context.read<CartBloc>().add(
                              UpdateQuantity(
                                productId: product.id,
                                quantity: quantity + 1,
                              ),
                            );
                          },
                          onDecrement: () {
                            // If quantity is 1, quantity - 1 is 0 which removes from CartBloc & Hive
                            context.read<CartBloc>().add(
                              UpdateQuantity(
                                productId: product.id,
                                quantity: quantity - 1,
                              ),
                            );
                          },
                          onRemove: () {
                            context.read<CartBloc>().add(
                              RemoveFromCart(product.id),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Fixed / Sticky Bottom Cart Summary
                  CartSummary(
                    uniqueItems: cartState.uniqueItems,
                    totalUnits: cartState.totalQuantity,
                    grandTotal: grandTotal,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
