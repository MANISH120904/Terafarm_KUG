import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'services/app_services.dart';
import 'widgets/state_views.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String category = 'Vegetables';
  bool _saving = false;

  Future<void> _addProduct() async {
    final user = AppServices.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to add products')),
        );
      }
      return;
    }

    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    if (name.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and price are required')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final sellerId = user.uid;
      final price = double.tryParse(priceText) ?? 0;
      final stock = stockController.text.trim().isEmpty
          ? '0'
          : stockController.text.trim();

      final productEntry = {
        'cropName': name,
        'pricePerKg': priceText,
        'stock in kgs': stock,
        'category': category,
        'description': descriptionController.text.trim(),
      };

      await AppServices.firestore.collection('products').add({
        'name': name,
        'price': price,
        'category': category,
        'description': descriptionController.text.trim(),
        'sellerId': sellerId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final farmQuery = await AppServices.firestore
          .collection('farms')
          .where('sellerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (farmQuery.docs.isNotEmpty) {
        final farmRef = farmQuery.docs.first.reference;
        final farmData = farmQuery.docs.first.data();
        final products = List<Map<String, dynamic>>.from(
          (farmData['products'] as List?)?.map(
                (e) => Map<String, dynamic>.from(e as Map),
              ) ??
              [],
        );
        products.add(productEntry);
        await farmRef.update({'products': products});
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add product: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppServices.auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Product')),
        body: const EmptyView(
          message: 'Sign in to list produce on your farm.',
          icon: Icons.add_shopping_cart,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price per kg'),
            ),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock (kg)'),
            ),
            DropdownButton<String>(
              value: category,
              isExpanded: true,
              items: ['Vegetables', 'Fruits', 'Herbs']
                  .map(
                    (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => category = value);
              },
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _addProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
