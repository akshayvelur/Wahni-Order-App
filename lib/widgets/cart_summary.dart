import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Fixed/sticky bottom summary displaying:
/// - Unique Items (e.g. "3 unique items in cart")
/// - Total Units (e.g. "Total Units: 12")
/// - Grand Total (e.g. "Grand Total: ₹149.95")
///
/// Grand total is calculated dynamically: sum(price × quantity).
/// Never persisted to Hive.
class CartSummary extends StatelessWidget {
  final int uniqueItems;
  final int totalUnits;
  final double grandTotal;
  final VoidCallback? onCheckout;

  const CartSummary({
    required this.uniqueItems,
    required this.totalUnits,
    required this.grandTotal,
    this.onCheckout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 6,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Unique items & Total Units row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$uniqueItems unique items in cart',
                    key: const ValueKey('cart_summary_unique_items'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Total Units: $totalUnits',
                    key: const ValueKey('cart_summary_total_units'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Grand Total row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Grand Total:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppConstants.currencySymbol}${grandTotal.toStringAsFixed(2)}',
                        key: const ValueKey('cart_summary_grand_total'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Checkout action button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('cart_summary_checkout_button'),
                  onPressed:
                      onCheckout ??
                      () {
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
    );
  }
}
