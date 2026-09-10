import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final int cartQuantity;
  final VoidCallback? onAddToCart;

  const ProductCard({
    required this.product,
    this.cartQuantity = 0,
    this.onAddToCart,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: ValueKey('product_card_${product.id}'),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product Image Container with optional In-Cart Badge
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: Image.network(
                      product.image,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Image unavailable',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
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
                // In-cart badge indicating synchronization with CartBloc
                if (cartQuantity > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      key: ValueKey('product_in_cart_badge_${product.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$cartQuantity in cart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Product Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${AppConstants.currencySymbol}${product.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onAddToCart ?? () {},
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: Text(
                      cartQuantity > 0
                          ? 'Add More ($cartQuantity)'
                          : 'Add to Cart',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
