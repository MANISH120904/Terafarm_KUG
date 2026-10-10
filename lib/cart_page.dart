import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'services/app_services.dart';
import 'services/cart_service.dart';
import 'widgets/app_image.dart';
import 'widgets/state_views.dart';

class CartPage extends StatefulWidget {
  /// Optional override for tests; normally uses [CartService].
  final List<Map<String, dynamic>>? cartItems;

  const CartPage({super.key, this.cartItems});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String _deliveryMethod = 'delivery';
  final int _deliveryFee = 30;
  bool _submitting = false;

  Future<void> _changeAddress(CartService cart) async {
    final controller = TextEditingController(text: cart.deliveryAddress);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery address'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter address'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      cart.deliveryAddress = result;
      setState(() {});
    }
  }

  Future<void> _confirmOrder(CartService cart) async {
    if (cart.isEmpty) return;
    final user = AppServices.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final items = cart.items.map((e) => Map<String, dynamic>.from(e)).toList();
      final sellerId = items.first['sellerId'] ?? 'unknown';
      final fee = _deliveryMethod == 'delivery' ? _deliveryFee : 0;
      final itemTotal = cart.itemTotal;
      final orderData = {
        'cartItems': items,
        'deliveryMethod': _deliveryMethod,
        'delivery': _deliveryMethod,
        'location': cart.deliveryAddress,
        'itemTotal': itemTotal,
        'deliveryFee': fee,
        'totalPayable': itemTotal + fee,
        'status': 'pending',
        'orderDate': DateTime.now().toIso8601String(),
        'buyerId': user.uid,
        'sellerId': sellerId,
      };

      await AppServices.firestore.collection('orders').add(orderData);
      cart.clear();

      if (!mounted) return;
      final msg = AppConfig.demoMode
          ? 'Demo order placed — no payment processed.'
          : 'Order confirmed!';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming order: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    // Support legacy constructor for any leftover call sites / tests.
    if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      for (final item in widget.cartItems!) {
        if (!cart.items.any((e) => e['name'] == item['name'])) {
          cart.addItem(item);
        }
      }
      widget.cartItems!.clear();
    }

    final items = cart.items;
    final cartCount = items.length;
    final itemTotal = cart.itemTotal;
    final totalPayable =
        _deliveryMethod == 'delivery' ? itemTotal + _deliveryFee : itemTotal;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: Text('Cart ($cartCount)'),
        actions: [
          TextButton(
            onPressed: cart.isEmpty ? null : cart.clear,
            child: const Text('Empty Cart', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: cartCount == 0
          ? const EmptyView(
              message: 'Your cart is empty.',
              icon: Icons.shopping_cart_outlined,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartCount,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final name = item['name'] ?? 'Unnamed';
                      final price = (item['price'] as num?)?.toInt() ?? 0;
                      final quantity = item['quantity'] as int? ?? 1;
                      final imagePath =
                          item['image']?.toString() ?? 'assets/sample_farm.png';
                      final unit = item['unit'] ?? '500 gms';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            AppImage(
                              source: imagePath,
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(unit.toString()),
                                    const SizedBox(height: 5),
                                    Text('₹$price Each'),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => cart.updateQuantity(
                                    index,
                                    quantity - 1,
                                  ),
                                ),
                                Text('$quantity'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => cart.updateQuantity(
                                    index,
                                    quantity + 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _row('Item Total', '₹$itemTotal'),
                  const SizedBox(height: 5),
                  _row(
                    'Delivery Fee',
                    _deliveryMethod == 'delivery' ? '₹$_deliveryFee' : '₹0',
                  ),
                  const SizedBox(height: 5),
                  _row('Total Payable', '₹$totalPayable', bold: true),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'How would you like to receive your order?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'delivery',
                        groupValue: _deliveryMethod,
                        onChanged: (value) {
                          setState(() => _deliveryMethod = value!);
                        },
                      ),
                      const Text('Delivery'),
                      const SizedBox(width: 20),
                      Radio<String>(
                        value: 'pickup',
                        groupValue: _deliveryMethod,
                        onChanged: (value) {
                          setState(() => _deliveryMethod = value!);
                        },
                      ),
                      const Text('Pick up'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Delivering between\n${cart.deliveryWindow}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.home, color: Colors.red),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          cart.deliveryAddress,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _changeAddress(cart),
                        child: const Text(
                          'CHANGE ADDRESS',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (AppConfig.demoMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Demo checkout — no real payment will be charged.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _confirmOrder(cart),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm Order',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 16,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
