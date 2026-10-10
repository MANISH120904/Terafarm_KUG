import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cart_page.dart';
import 'services/cart_service.dart';
import 'widgets/app_bottom_nav.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final List<Map<String, dynamic>> farmingTools = [
    {'name': 'Pots', 'image': 'assets/pot.png', 'quantity': 0, 'price': 50},
    {
      'name': 'Grow Bags',
      'image': 'assets/growing_bags.png',
      'quantity': 0,
      'price': 80,
    },
  ];

  final List<Map<String, dynamic>> seeds = [
    {
      'name': 'Tomato seeds',
      'image': 'assets/tomato_seed.png',
      'quantity': 0,
      'price': 30,
    },
    {'name': 'Beans seeds', 'image': 'assets/beans.png', 'quantity': 0, 'price': 25},
    {'name': 'Apple seeds', 'image': 'assets/Apple.png', 'quantity': 0, 'price': 40},
    {'name': 'Grape seeds', 'image': 'assets/grape.png', 'quantity': 0, 'price': 35},
  ];

  void _syncShopLine(CartService cart, Map<String, dynamic> item) {
    final name = item['name'] as String;
    final qty = item['quantity'] as int;
    final idx = cart.items.indexWhere(
      (e) => e['name'] == name && e['type'] == 'shop',
    );
    if (qty <= 0) {
      if (idx >= 0) cart.removeAt(idx);
      return;
    }
    if (idx >= 0) {
      cart.updateQuantity(idx, qty);
    } else {
      cart.addItem({
        'name': name,
        'image': item['image'],
        'price': item['price'],
        'quantity': qty,
        'type': 'shop',
      });
    }
  }

  void _syncToCart(CartService cart) {
    for (final item in [...farmingTools, ...seeds]) {
      _syncShopLine(cart, item);
    }
  }

  void updateQuantity(
    List<Map<String, dynamic>> category,
    int index,
    int change,
  ) {
    setState(() {
      category[index]['quantity'] =
          ((category[index]['quantity'] as int) + change).clamp(0, 99);
    });
    _syncToCart(context.read<CartService>());
  }

  bool hasItemsInCart() {
    return farmingTools.any((item) => (item['quantity'] as int) > 0) ||
        seeds.any((item) => (item['quantity'] as int) > 0);
  }

  Widget buildInventoryItem(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> category,
    int index,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Row(
          children: [
            Image.asset(
              item['image'] as String,
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey.shade600,
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item['name'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade200,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.red),
                    onPressed: () => updateQuantity(category, index, -1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item['quantity']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => updateQuantity(category, index, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _buyNow() {
    _syncToCart(context.read<CartService>());
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Shop'),
        backgroundColor: Colors.green.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            const Text(
              'Inventory',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Farming tools',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...farmingTools.asMap().entries.map(
              (entry) => buildInventoryItem(
                entry.value,
                farmingTools,
                entry.key,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Seeds',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...seeds.asMap().entries.map(
              (entry) => buildInventoryItem(entry.value, seeds, entry.key),
            ),
          ],
        ),
      ),
      floatingActionButton: hasItemsInCart()
          ? FloatingActionButton.extended(
              backgroundColor: Colors.green,
              onPressed: _buyNow,
              label: const Text('Buy Now'),
              icon: const Icon(Icons.shopping_cart),
            )
          : null,
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}
