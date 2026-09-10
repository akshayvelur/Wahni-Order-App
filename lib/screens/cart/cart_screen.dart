import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../bloc/cart/cart_state.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_state.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product_model.dart';

class CartScreen extends StatelessWidget {
  final VoidCallback? onBrowseProducts;

  const CartScreen({this.onBrowseProducts, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart'), centerTitle: true),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState.quantities.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Looks like you haven\'t added any items yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onBrowseProducts,
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Browse Products'),
                    ),
                  ],
                ),
              ),
            );
          }

          return BlocBuilder<ProductBloc, ProductState>(
            builder: (context, productState) {
              final List<ProductModel> products = productState is ProductSuccess
                  ? productState.products
                  : [];

              final Map<int, ProductModel> productMap = {
                for (final p in products) p.id: p,
              };

              // Compute total price dynamically
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
                  // Cart Items List
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
                          // Product not loaded yet or fallback
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

                        final lineTotal = product.price * quantity;

                        return Card(
                          key: ValueKey('cart_item_$productId'),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Thumbnail
                                Container(
                                  width: 64,
                                  height: 64,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.network(
                                    product.image,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.grey,
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${AppConstants.currencySymbol}${product.price.toStringAsFixed(2)} each',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.grey[700]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total: ${AppConstants.currencySymbol}${lineTotal.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Controls
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      iconSize: 20,
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: () {
                                        context.read<CartBloc>().add(
                                          UpdateQuantity(
                                            productId: productId,
                                            quantity: quantity - 1,
                                          ),
                                        );
                                      },
                                    ),
                                    Text(
                                      '$quantity',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    IconButton(
                                      iconSize: 20,
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () {
                                        context.read<CartBloc>().add(
                                          UpdateQuantity(
                                            productId: productId,
                                            quantity: quantity + 1,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Order Summary Footer
                  Surface(
                    elevation: 4,
                    color: theme.colorScheme.surfaceContainer,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Items: ${cartState.totalQuantity} (${cartState.uniqueItems} unique)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'Grand Total',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Estimated Delivery: FREE',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${AppConstants.currencySymbol}${grandTotal.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Order for ${AppConstants.currencySymbol}${grandTotal.toStringAsFixed(2)} placed successfully!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Proceed to Checkout'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

/// Helper wrapper container for footer styling
class Surface extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double elevation;

  const Surface({
    required this.child,
    this.color,
    this.elevation = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      elevation: elevation,
      child: child,
    );
  }
}
