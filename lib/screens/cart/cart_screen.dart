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
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          // Empty cart state
          if (cartState.quantities.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE0E7FF),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.remove_shopping_cart_outlined,
                        size: 44,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your cart is empty',
                      key: const ValueKey('empty_cart_title'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some products to continue shopping.',
                      key: const ValueKey('empty_cart_subtitle'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        key: const ValueKey('continue_shopping_button'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleContinueShopping(context),
                        icon: const Icon(Icons.storefront_outlined, size: 18),
                        label: const Text('Continue Shopping'),
                      ),
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
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              title: Text(
                                'Product #$productId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
