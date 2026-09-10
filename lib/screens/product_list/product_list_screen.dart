import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../bloc/cart/cart_state.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wahni Products'), centerTitle: true),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading || state is ProductInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load products',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        context.read<ProductBloc>().add(const RetryProducts());
                      },
                      icon: const Icon(Icons.refresh),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('No products available at the moment.'),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<ProductBloc>().add(
                          const RefreshProducts(),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
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
                  onRefresh: () async {
                    context.read<ProductBloc>().add(const RefreshProducts());
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
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
