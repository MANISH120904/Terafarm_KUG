import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cart_page.dart';
import 'services/app_services.dart';
import 'services/cart_service.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/app_image.dart';
import 'widgets/notifications_sheet.dart';
import 'widgets/state_views.dart';

class ProductPage extends StatefulWidget {
  final String farmId;

  const ProductPage({super.key, required this.farmId});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final Map<int, int> _quantities = {};
  String _search = '';

  int _getUnitPrice(String productName, dynamic firestorePrice) {
    return int.tryParse(firestorePrice.toString()) ??
        (num.tryParse(firestorePrice.toString())?.round() ?? 0);
  }

  String _assetForCrop(String name) {
    final lower = name.toLowerCase();
    const known = {
      'onion': 'assets/onion.png',
      'tomato': 'assets/tomato.png',
      'beans': 'assets/beans.png',
      'greens': 'assets/greens.png',
      'apple': 'assets/Apple.png',
      'grape': 'assets/grape.png',
    };
    for (final entry in known.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'assets/sample_farm.png';
  }

  bool get _hasAnyQuantity => _quantities.values.any((qty) => qty > 0);

  void _addToCartAndGo(
    List products,
    String sellerId,
    CartService cart,
  ) {
    for (int i = 0; i < products.length; i++) {
      final product = products[i] as Map<String, dynamic>;
      final quantity = _quantities[i] ?? 0;
      if (quantity <= 0) continue;
      final name = product['cropName']?.toString() ?? 'Item';
      cart.addItem({
        'name': name,
        'price': _getUnitPrice(name, product['pricePerKg']),
        'quantity': quantity,
        'image': _assetForCrop(name),
        'unit': '500 gms',
        'sellerId': sellerId,
      });
    }
    setState(() {
      for (final key in _quantities.keys) {
        _quantities[key] = 0;
      }
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return StreamBuilder<DocumentSnapshot>(
      stream: AppServices.firestore
          .collection('farms')
          .doc(widget.farmId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: EmptyView(message: 'Farm not found.'),
          );
        }

        final farmData = snapshot.data!.data() as Map<String, dynamic>;
        final farmName = farmData['farmName'] ?? 'Unnamed Farm';
        final farmDesc =
            farmData['farmDescription'] ?? 'No description available.';
        final scale = farmData['scale'] ?? 'N/A';
        final rating = farmData['rating'] ?? 4.0;
        final imageUrl =
            farmData['imageUrl']?.toString() ?? 'assets/sample_farm.png';
        final distanceCharge = farmData['distanceCharge'] ?? 10;
        final sellerId = farmData['sellerId']?.toString() ?? 'unknown';
        final List products = farmData['products'] as List? ?? [];

        for (int i = 0; i < products.length; i++) {
          _quantities.putIfAbsent(i, () => 0);
        }

        final filteredIndexes = <int>[];
        for (int i = 0; i < products.length; i++) {
          final name =
              (products[i] as Map)['cropName']?.toString().toLowerCase() ?? '';
          if (_search.isEmpty || name.contains(_search.toLowerCase())) {
            filteredIndexes.add(i);
          }
        }

        Widget? bottomBar;
        if (_hasAnyQuantity) {
          bottomBar = Container(
            height: 60,
            color: Colors.red,
            child: InkWell(
              onTap: () => _addToCartAndGo(products, sellerId, cart),
              child: const Center(
                child: Text(
                  'Buy Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green.shade900,
            title: Row(
              children: [
                Transform.translate(
                  offset: const Offset(-40, 5),
                  child: Image.asset('assets/terafarm_logo.png', height: 40),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () => showNotificationsSheet(context),
              ),
              AppBottomNav.cartAction(context),
            ],
          ),
          bottomNavigationBar: bottomBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppImage(
                  source: imageUrl,
                  height: 200,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 10),
                Text(
                  farmName.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  farmDesc.toString(),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scale: $scale'),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        Text(rating.toString()),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bike, color: Colors.black54),
                      const SizedBox(width: 5),
                      Text('₹$distanceCharge distance charge'),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Available products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _search = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (filteredIndexes.isEmpty)
                  const EmptyView(message: 'No products match your search.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredIndexes.length,
                    itemBuilder: (context, displayIndex) {
                      final index = filteredIndexes[displayIndex];
                      final product = products[index] as Map<String, dynamic>;
                      final productName =
                          product['cropName']?.toString() ?? 'Unnamed';
                      final unitPrice =
                          _getUnitPrice(productName, product['pricePerKg']);
                      final productStock = product['stock in kgs'] ?? '0';
                      final quantity = _quantities[index] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              AppImage(
                                source: _assetForCrop(productName),
                                width: 100,
                                height: 100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '$productStock kg in stock · ₹$unitPrice / kg',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                        Text('4.5'),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if ((_quantities[index] ??
                                                          0) >
                                                      0) {
                                                    _quantities[index] =
                                                        _quantities[index]! - 1;
                                                  }
                                                });
                                              },
                                            ),
                                            Text('$quantity'),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _quantities[index] =
                                                      (_quantities[index] ??
                                                          0) +
                                                      1;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '₹${unitPrice * quantity}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
