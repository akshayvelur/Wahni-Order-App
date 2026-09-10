import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_state.dart';
import 'cart/cart_screen.dart';
import 'product_list/product_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ProductListScreen(onOpenCart: () => _onDestinationSelected(1)),
          CartScreen(
            onContinueShopping: () => _onDestinationSelected(0),
            onBrowseProducts: () => _onDestinationSelected(0),
          ),
        ],
      ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final uniqueItems = cartState.uniqueItems;

          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Badge(
                  key: const ValueKey('bottom_nav_cart_badge'),
                  isLabelVisible: uniqueItems > 0,
                  label: Text(
                    '$uniqueItems',
                    key: const ValueKey('bottom_nav_cart_badge_count'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                selectedIcon: Badge(
                  key: const ValueKey('bottom_nav_cart_selected_badge'),
                  isLabelVisible: uniqueItems > 0,
                  label: Text(
                    '$uniqueItems',
                    key: const ValueKey('bottom_nav_cart_selected_badge_count'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Icon(Icons.shopping_cart),
                ),
                label: 'Cart',
              ),
            ],
          );
        },
      ),
    );
  }
}
