import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final int cartQuantity;
  final VoidCallback? onAddToCart;
  final ValueChanged<int>? onUpdateQuantity;

  const ProductCard({
    required this.product,
    this.cartQuantity = 0,
    this.onAddToCart,
    this.onUpdateQuantity,
    super.key,
  });

  Future<void> _showQuantityEditDialog(BuildContext context) async {
    if (onUpdateQuantity == null) return;

    final textController = TextEditingController(text: '$cartQuantity');
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
                  key: ValueKey('product_quantity_input_${product.id}'),
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: ValueKey('product_quantity_submit_${product.id}'),
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

    if (newQuantity != null) {
      onUpdateQuantity!(newQuantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inCart = cartQuantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        key: ValueKey('product_card_${product.id}'),
        elevation: 0,
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image Canvas with optional In-Cart Badge
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Image.network(
                        product.image,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2.5,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    size: 28,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Image unavailable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // In-cart badge indicating synchronization with CartBloc (tappable to type quantity)
                  if (inCart)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: ValueKey('product_in_cart_badge_${product.id}'),
                          onTap: () => _showQuantityEditDialog(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981), // Emerald dot
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$cartQuantity in cart',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Details Area
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Price with bold Indian Rupee format
                  Text(
                    '${AppConstants.currencySymbol}${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: inCart
                        ? FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEEF2FF),
                              foregroundColor: theme.colorScheme.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: onAddToCart ?? () {},
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: Text(
                              'Add More ($cartQuantity)',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: onAddToCart ?? () {},
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text(
                              'Add to Cart',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
