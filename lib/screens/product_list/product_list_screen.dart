import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../bloc/cart/cart_state.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import '../../widgets/product_card.dart';
import '../cart/cart_screen.dart';

class ProductListScreen extends StatelessWidget {
  final VoidCallback? onOpenCart;

  const ProductListScreen({this.onOpenCart, super.key});

  int _getCrossAxisCount(double width) {
    if (width < 600) {
      return 2; // Small screen (mobile portrait)
    } else if (width < 900) {
      return 3; // Medium screen (tablet / mobile landscape)
    } else if (width < 1200) {
      return 4; // Large screen (desktop / tablet landscape)
    } else {
      return 5; // Extra large / wide screens
    }
  }

  void _handleCartTap(BuildContext context) {
    if (onOpenCart != null) {
      onOpenCart!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
    }
  }

  Widget _buildCartAppBarAction(BuildContext context) {
    CartState? cartState;
    try {
      cartState = context.watch<CartBloc>().state;
    } catch (_) {
      cartState = null;
    }

    // Displays CartBloc.uniqueItems (NOT totalQuantity)
    final uniqueItems = cartState?.uniqueItems ?? 0;

    return IconButton(
      key: const ValueKey('appbar_cart_button'),
      tooltip: 'Cart ($uniqueItems unique items)',
      icon: Badge(
        key: const ValueKey('appbar_cart_badge'),
        isLabelVisible: uniqueItems > 0,
        label: Text(
          '$uniqueItems',
          key: const ValueKey('appbar_cart_badge_count'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
      onPressed: () => _handleCartTap(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wahni Products',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [_buildCartAppBarAction(context), const SizedBox(width: 8)],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading || state is ProductInitial) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading catalog...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ProductFailure) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Failed to load products',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: const Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        context.read<ProductBloc>().add(const RetryProducts());
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ProductSuccess) {
            if (state.products.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No products available at the moment.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check back later or refresh the catalog.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<ProductBloc>().add(
                            const RefreshProducts(),
                          );
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Watch CartBloc state to keep Product Listing synchronized with Cart
            CartState? cartState;
            try {
              cartState = context.watch<CartBloc>().state;
            } catch (_) {
              cartState = null;
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

                return RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: () async {
                    context.read<ProductBloc>().add(const RefreshProducts());
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.64,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      final inCartQuantity =
                          cartState?.getQuantity(product.id) ?? 0;

                      return ProductCard(
                        key: ValueKey('product_${product.id}'),
                        product: product,
                        cartQuantity: inCartQuantity,
                        onAddToCart: () {
                          try {
                            context.read<CartBloc>().add(AddToCart(product.id));
                          } catch (_) {}
                        },
                        onUpdateQuantity: (newQty) {
                          try {
                            context.read<CartBloc>().add(
                              UpdateQuantity(
                                productId: product.id,
                                quantity: newQty,
                              ),
                            );
                          } catch (_) {}
                        },
                      );
                    },
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
