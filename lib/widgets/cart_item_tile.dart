import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';
import '../core/constants/app_constants.dart';
import '../data/models/product_model.dart';

/// Reusable Cart Item Tile that displays:
/// - Product image
/// - Product name (title)
/// - Unit price
/// - Current quantity with [-] and [+] controls
/// - Subtotal (unit price × quantity)
///
/// Dispatches [UpdateQuantity] and [RemoveFromCart] events to [CartBloc].
class CartItemTile extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;

  const CartItemTile({
    required this.product,
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
    super.key,
  });

  /// subtotal = unit price × quantity
  double get subtotal => product.price * quantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: ValueKey('cart_item_${product.id}'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product image
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
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product name, unit price, and subtotal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    key: ValueKey('cart_item_title_${product.id}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unit Price: ${AppConstants.currencySymbol}${product.price.toStringAsFixed(2)}',
                    key: ValueKey('cart_item_unit_price_${product.id}'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: ${AppConstants.currencySymbol}${subtotal.toStringAsFixed(2)}',
                    key: ValueKey('cart_item_subtotal_${product.id}'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // [-] quantity [+] controls & remove
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // [-] Decrement button
                    IconButton(
                      key: ValueKey('cart_item_decrement_${product.id}'),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Decrease quantity',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed:
                          onDecrement ??
                          () {
                            context.read<CartBloc>().add(
                              UpdateQuantity(
                                productId: product.id,
                                quantity: quantity - 1,
                              ),
                            );
                          },
                    ),

                    // Current quantity text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        '$quantity',
                        key: ValueKey('cart_item_quantity_${product.id}'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // [+] Increment button
                    IconButton(
                      key: ValueKey('cart_item_increment_${product.id}'),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Increase quantity',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed:
                          onIncrement ??
                          () {
                            context.read<CartBloc>().add(
                              UpdateQuantity(
                                productId: product.id,
                                quantity: quantity + 1,
                              ),
                            );
                          },
                    ),
                  ],
                ),
                // Quick remove button
                InkWell(
                  key: ValueKey('cart_item_remove_${product.id}'),
                  onTap:
                      onRemove ??
                      () {
                        context.read<CartBloc>().add(
                          RemoveFromCart(product.id),
                        );
                      },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      'Remove',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
