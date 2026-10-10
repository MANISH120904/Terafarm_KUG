import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/app_services.dart';
import 'state_views.dart';

Future<void> showNotificationsSheet(BuildContext context) async {
  final uid = AppServices.auth.currentUser?.uid;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, controller) {
          if (uid == null) {
            return const EmptyView(message: 'Sign in to see notifications.');
          }
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: AppServices.firestore
                      .collection('notifications')
                      .where('userId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingView();
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const EmptyView(
                        message: 'No notifications yet.',
                        icon: Icons.notifications_none,
                      );
                    }
                    final sorted = [...docs]..sort((a, b) {
                      final aTs = (a.data() as Map)['createdAt'];
                      final bTs = (b.data() as Map)['createdAt'];
                      final aDate = aTs is Timestamp
                          ? aTs.toDate()
                          : DateTime.fromMillisecondsSinceEpoch(0);
                      final bDate = bTs is Timestamp
                          ? bTs.toDate()
                          : DateTime.fromMillisecondsSinceEpoch(0);
                      return bDate.compareTo(aDate);
                    });
                    return ListView.builder(
                      controller: controller,
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final data =
                            sorted[index].data() as Map<String, dynamic>;
                        final read = data['read'] == true;
                        return ListTile(
                          leading: Icon(
                            read
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: read ? Colors.grey : Colors.orange,
                          ),
                          title: Text(
                            data['title']?.toString() ?? 'Update',
                            style: TextStyle(
                              fontWeight:
                                  read ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(data['body']?.toString() ?? ''),
                          onTap: () async {
                            await sorted[index].reference.update({'read': true});
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
