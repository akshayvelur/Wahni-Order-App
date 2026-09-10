import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';
import '../core/constants/app_constants.dart';
import '../data/models/product_model.dart';
import 'quantity_input.dart';

/// Reusable Cart Item Tile that displays:
/// - Product image with fallback
/// - Product name (title)
/// - Unit price
/// - Current quantity with inline [QuantityInput] ([-] input [+])
/// - Subtotal (unit price × quantity)
/// - Quick dialog edit option & remove button
///
/// Dispatches [UpdateQuantity] and [RemoveFromCart] events to [CartBloc].
class CartItemTile extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;
  final ValueChanged<int>? onDirectQuantityChange;

  const CartItemTile({
    required this.product,
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
    this.onDirectQuantityChange,
    super.key,
  });

  /// subtotal = unit price × quantity
  double get subtotal => product.price * quantity;

  Future<void> _showQuantityEditDialog(BuildContext context) async {
    final textController = TextEditingController(text: '$quantity');
    final formKey = GlobalKey<FormState>();

    final newQuantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Edit Quantity',
            style: Theme.of(dialogContext).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(dialogContext).textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('quantity_input_field'),
                  controller: textController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity (0 to remove)',
                    hintText: 'e.g. 1, 5, 10',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a quantity';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null) {
                      return 'Please enter a valid whole number';
                    }
                    if (parsed < 0) {
                      return 'Quantity cannot be negative';
                    }
                    if (parsed > 9999) {
                      return 'Maximum quantity is 9999';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('quantity_cancel_button'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('quantity_submit_button'),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final val = int.parse(textController.text.trim());
                  Navigator.of(dialogContext).pop(val);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (newQuantity != null && context.mounted) {
      if (onDirectQuantityChange != null) {
        onDirectQuantityChange!(newQuantity);
      } else {
        context.read<CartBloc>().add(
          UpdateQuantity(productId: product.id, quantity: newQuantity),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        key: ValueKey('cart_item_${product.id}'),
        elevation: 0,
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product image with rounded frame
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Image.network(
                  product.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF94A3B8),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),

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
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Unit Price: ${AppConstants.currencySymbol}${product.price.toStringAsFixed(2)}',
                      key: ValueKey('cart_item_unit_price_${product.id}'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Subtotal: ${AppConstants.currencySymbol}${subtotal.toStringAsFixed(2)}',
                      key: ValueKey('cart_item_subtotal_${product.id}'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Inline [-] QuantityInput [+] and actions
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuantityInput(
                        quantity: quantity,
                        decrementKey: ValueKey(
                          'cart_item_decrement_${product.id}',
                        ),
                        inputKey: ValueKey('cart_item_quantity_${product.id}'),
                        incrementKey: ValueKey(
                          'cart_item_increment_${product.id}',
                        ),
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                        onQuantityChanged: (newQty) {
                          if (newQty <= 0) {
                            if (onRemove != null) {
                              onRemove!();
                            } else {
                              context.read<CartBloc>().add(
                                UpdateQuantity(
                                  productId: product.id,
                                  quantity: 0,
                                ),
                              );
                            }
                          } else {
                            if (onDirectQuantityChange != null) {
                              onDirectQuantityChange!(newQty);
                            } else {
                              context.read<CartBloc>().add(
                                UpdateQuantity(
                                  productId: product.id,
                                  quantity: newQty,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      // Quick edit dialog icon button
                      IconButton(
                        key: ValueKey('cart_item_quantity_tap_${product.id}'),
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Open quantity dialog',
                        icon: const Icon(
                          Icons.edit_note,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () => _showQuantityEditDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 13,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
