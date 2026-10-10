import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'services/app_services.dart';
import 'widgets/app_image.dart';
import 'widgets/state_views.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AppServices.auth.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const EmptyView(message: 'Please sign in to view orders.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: const Text('My Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AppServices.firestore
            .collection('orders')
            .where('buyerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(message: 'Could not load orders: ${snapshot.error}');
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const EmptyView(
              message: 'No orders yet. Browse farms and add items to cart.',
              icon: Icons.shopping_bag_outlined,
            );
          }

          final sorted = [...docs]..sort((a, b) {
            final aDate = (a.data() as Map)['orderDate']?.toString() ?? '';
            final bDate = (b.data() as Map)['orderDate']?.toString() ?? '';
            return bDate.compareTo(aDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final data = sorted[index].data() as Map<String, dynamic>;
              final items = (data['cartItems'] as List?) ?? [];
              final first = items.isNotEmpty
                  ? Map<String, dynamic>.from(items.first as Map)
                  : <String, dynamic>{};
              final status = data['status']?.toString() ?? 'pending';
              final total = data['totalPayable'] ?? 0;
              final image = first['image']?.toString() ?? 'assets/sample_farm.png';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: AppImage(
                    source: image,
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  title: Text(
                    first['name']?.toString() ?? 'Order',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Status: $status\nTotal: ₹$total · ${data['deliveryMethod'] ?? data['delivery'] ?? 'delivery'}',
                  ),
                  isThreeLine: true,
                  trailing: _statusChip(status),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'accepted':
        color = Colors.blue;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
