import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../community_page.dart';
import '../dashboard_page.dart';
import '../home_page.dart';
import '../services/cart_service.dart';
import '../shop_page.dart';
import '../cart_page.dart';
import '../core/app_theme.dart';

/// Shared bottom navigation that replaces the stack instead of pushing forever.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  /// 0 Home, 1 Community, 2 Farm/Dashboard, 3 Shop, 4 Cart (via icon).
  final int currentIndex;

  void _go(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartService>().itemCount;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex.clamp(0, 3),
      selectedItemColor: AppTheme.brandGreen,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == currentIndex && index != 4) return;
        switch (index) {
          case 0:
            _go(context, const HomePage());
            break;
          case 1:
            _go(context, const CommunityPage());
            break;
          case 2:
            _go(context, const DashboardPage());
            break;
          case 3:
            _go(context, const ShopPage());
            break;
        }
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          activeIcon: Icon(Icons.groups),
          label: 'Community',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.agriculture_outlined),
          activeIcon: Icon(Icons.agriculture),
          label: 'Farm',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: const Icon(Icons.storefront_outlined),
          ),
          activeIcon: const Icon(Icons.storefront),
          label: 'Shop',
        ),
      ],
    );
  }

  static Widget cartAction(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cart, _) {
        return IconButton(
          tooltip: 'Cart',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            );
          },
          icon: Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        );
      },
    );
  }
}
