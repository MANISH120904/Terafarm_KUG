import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'services/app_services.dart';
import 'widgets/app_image.dart';
import 'widgets/state_views.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await AppServices.firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  String _deliveryLabel(Map<String, dynamic> data) {
    return (data['deliveryMethod'] ?? data['delivery'] ?? 'pickup')
        .toString();
  }

  String _locationLabel(Map<String, dynamic> data) {
    return (data['location'] ?? data['deliveryAddress'] ?? 'Unknown')
        .toString();
  }

  String _productImage(Map<String, dynamic> data) {
    final cartItems = data['cartItems'] as List?;
    if (cartItems == null || cartItems.isEmpty) {
      return 'assets/placeholder.png';
    }
    final first = cartItems.first;
    if (first is Map) {
      return (first['image'] ?? 'assets/placeholder.png').toString();
    }
    return 'assets/placeholder.png';
  }

  @override
  Widget build(BuildContext context) {
    final user = AppServices.auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green.shade800,
          title: const Text('Orders', style: TextStyle(color: Colors.white)),
        ),
        body: const EmptyView(
          message: 'Sign in to manage orders.',
          icon: Icons.receipt_long,
        ),
      );
    }

    final sellerId = user.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade800,
        title: const Text(
          'Orders',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AppServices.firestore
            .collection('orders')
            .where('sellerId', isEqualTo: sellerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(message: '${snapshot.error}');
          }

          final allOrders = snapshot.data?.docs ?? [];

          final pendingOrders = allOrders
              .where((doc) => (doc['status'] ?? 'pending') == 'pending')
              .toList();

          final acceptedOrders = allOrders
              .where((doc) => (doc['status'] ?? '') == 'accepted')
              .toList();

          final completedOrders = allOrders.where((doc) {
            final s = (doc['status'] ?? '').toString().toLowerCase();
            return s == 'rejected' || s == 'delivered' || s == 'cancelled';
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                if (pendingOrders.isEmpty && acceptedOrders.isEmpty)
                  const Text('No pending orders.')
                else ...[
                  for (final doc in pendingOrders)
                    _buildOrderCard(doc, status: 'pending'),
                  for (final doc in acceptedOrders)
                    _buildOrderCard(doc, status: 'accepted'),
                ],
                const SizedBox(height: 20),
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                if (completedOrders.isEmpty)
                  const Text('No completed orders.')
                else
                  for (final doc in completedOrders)
                    _buildOrderCard(
                      doc,
                      status: doc['status']?.toString() ?? '',
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot orderDoc, {required String status}) {
    final data = orderDoc.data() as Map<String, dynamic>;
    final String orderId = orderDoc.id;
    final String buyerId = data['buyerId']?.toString() ?? 'unknown';
    final location = _locationLabel(data);
    final deliveryType = _deliveryLabel(data);
    final productImage = _productImage(data);

    return FutureBuilder<DocumentSnapshot>(
      future: AppServices.firestore.collection('users').doc(buyerId).get(),
      builder: (context, snapshot) {
        final buyerName = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.get('username')?.toString() ?? 'Unknown'
            : 'Unknown';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                AppImage(
                  source: productImage,
                  width: 60,
                  height: 60,
                  borderRadius: BorderRadius.circular(8),
                  fallbackAsset: 'assets/placeholder.png',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buyerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Location: $location'),
                      Text('Delivery: $deliveryType'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionButtons(status, orderId),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(String status, String orderId) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _updateOrderStatus(orderId, 'accepted'),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _updateOrderStatus(orderId, 'rejected'),
            ),
          ],
        );

      case 'accepted':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(80, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onPressed: () => _updateOrderStatus(orderId, 'delivered'),
              child: const Text('Delivered', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(80, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onPressed: () => _updateOrderStatus(orderId, 'cancelled'),
              child: const Text('Cancelled', style: TextStyle(fontSize: 14)),
            ),
          ],
        );

      case 'rejected':
        return _buildStatusLabel('cancelled');

      case 'delivered':
        return _buildStatusLabel('delivered');

      case 'cancelled':
        return _buildStatusLabel('cancelled');

      default:
        return _buildStatusLabel(status);
    }
  }

  Widget _buildStatusLabel(String status) {
    late Color bgColor;
    late String text;
    switch (status.toLowerCase()) {
      case 'rejected':
      case 'cancelled':
        bgColor = Colors.red;
        text = 'Cancelled';
        break;
      case 'delivered':
        bgColor = Colors.green;
        text = 'Delivered';
        break;
      default:
        bgColor = Colors.grey;
        text = status.isEmpty
            ? 'Unknown'
            : status[0].toUpperCase() + status.substring(1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
