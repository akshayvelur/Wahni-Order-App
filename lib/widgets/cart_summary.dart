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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subtle top drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Unique items & Total Units row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$uniqueItems unique items in cart',
                      key: const ValueKey('cart_summary_unique_items'),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'Total Units: $totalUnits',
                    key: const ValueKey('cart_summary_total_units'),
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Delivery indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Delivery fee:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),

              // Grand Total row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Grand Total:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${grandTotal.toStringAsFixed(2)}',
                    key: const ValueKey('cart_summary_grand_total'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Checkout action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  key: const ValueKey('cart_summary_checkout_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  onPressed:
                      onCheckout ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Order for ${AppConstants.currencySymbol}${grandTotal.toStringAsFixed(2)} placed successfully!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
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
