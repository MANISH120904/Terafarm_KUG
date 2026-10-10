import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'services/app_services.dart';
import 'widgets/app_image.dart';
import 'widgets/state_views.dart';

class ColabPage extends StatefulWidget {
  const ColabPage({super.key});

  @override
  State<ColabPage> createState() => _ColabPageState();
}

class _ColabPageState extends State<ColabPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool isReadyToCollab = false;
  String? userFarmId;
  bool _farmLoaded = false;
  String? _currentUserId;
  Map<String, DocumentSnapshot> _sentRequests = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUserId = AppServices.auth.currentUser?.uid;
    if (_currentUserId != null) {
      _loadUserFarm();
      _loadSentRequests();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserFarm() async {
    final uid = _currentUserId;
    if (uid == null) return;

    final query = await AppServices.firestore
        .collection('farms')
        .where('sellerId', isEqualTo: uid)
        .limit(1)
        .get();

    if (!mounted) return;
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      setState(() {
        userFarmId = doc.id;
        isReadyToCollab = doc['isReadyToCollab'] == true;
        _farmLoaded = true;
      });
    } else {
      setState(() {
        userFarmId = null;
        _farmLoaded = true;
      });
    }
  }

  Future<void> _loadSentRequests() async {
    final uid = _currentUserId;
    if (uid == null) return;

    final query = await AppServices.firestore
        .collection('collabRequests')
        .where('requesterId', isEqualTo: uid)
        .get();

    if (!mounted) return;
    setState(() {
      _sentRequests = {for (final doc in query.docs) doc['farmId']: doc};
    });
  }

  Future<void> _updateReadiness(bool value) async {
    if (userFarmId == null) return;
    await AppServices.firestore
        .collection('farms')
        .doc(userFarmId)
        .update({'isReadyToCollab': value});
    if (!mounted) return;
    setState(() {
      isReadyToCollab = value;
    });
  }

  Future<void> _sendCollabRequest(String farmId) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final docRef =
        await AppServices.firestore.collection('collabRequests').add({
      'farmId': farmId,
      'requesterId': uid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    final newDoc = await docRef.get();
    if (!mounted) return;
    setState(() {
      _sentRequests[farmId] = newDoc;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Collaboration request sent!')),
    );
  }

  Future<void> _cancelRequest(String requestId, String farmId) async {
    await AppServices.firestore
        .collection('collabRequests')
        .doc(requestId)
        .delete();

    if (!mounted) return;
    setState(() {
      _sentRequests.remove(farmId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request cancelled.')),
    );
  }

  Future<void> _approveRequest(String requestId) async {
    await AppServices.firestore
        .collection('collabRequests')
        .doc(requestId)
        .update({'status': 'approved'});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request approved.')),
    );
  }

  Future<void> _rejectRequest(String requestId) async {
    await AppServices.firestore
        .collection('collabRequests')
        .doc(requestId)
        .update({'status': 'rejected'});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request rejected.')),
    );
  }

  Future<void> _endCollaboration(String requestId) async {
    await AppServices.firestore
        .collection('collabRequests')
        .doc(requestId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Collaboration ended.')),
    );
  }

  String _farmTitle(Map<String, dynamic> data) {
    return (data['farmName'] ?? data['name'] ?? 'Unnamed Farm').toString();
  }

  Widget _buildApplyRequestsTab() {
    final uid = _currentUserId;
    if (uid == null) {
      return const EmptyView(
        message: 'Sign in to explore collaborations.',
        icon: Icons.group,
      );
    }

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Ready to Collab?'),
          subtitle: userFarmId == null && _farmLoaded
              ? const Text('List a farm on your dashboard first.')
              : null,
          value: isReadyToCollab,
          onChanged: userFarmId == null ? null : _updateReadiness,
        ),
        if (isReadyToCollab)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AppServices.firestore
                  .collection('farms')
                  .where('isReadyToCollab', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final farms = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['sellerId'] != uid;
                }).toList();

                if (farms.isEmpty) {
                  return const Center(child: Text('No farms are ready.'));
                }

                return ListView.builder(
                  itemCount: farms.length,
                  itemBuilder: (context, index) {
                    final doc = farms[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final farmId = doc.id;
                    final requestDoc = _sentRequests[farmId];
                    final requestStatus =
                        requestDoc?.get('status')?.toString();

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: AppImage(
                          source: data['imageUrl']?.toString(),
                          width: 60,
                          height: 60,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        title: Text(_farmTitle(data)),
                        subtitle: Text(
                          'Location: ${data['location'] ?? 'Unknown'}',
                        ),
                        trailing: requestStatus == null
                            ? ElevatedButton(
                                onPressed: () => _sendCollabRequest(farmId),
                                child: const Text('Request'),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    requestStatus[0].toUpperCase() +
                                        requestStatus.substring(1),
                                    style: TextStyle(
                                      color: requestStatus == 'approved'
                                          ? Colors.green
                                          : requestStatus == 'rejected'
                                              ? Colors.red
                                              : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (requestStatus == 'pending')
                                    IconButton(
                                      icon: const Icon(Icons.cancel),
                                      color: Colors.red,
                                      onPressed: () => _cancelRequest(
                                        requestDoc!.id,
                                        farmId,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPendingRequestsTab() {
    if (!_farmLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userFarmId == null) {
      return const EmptyView(
        message: 'Register a farm to receive collaboration requests.',
        icon: Icons.agriculture,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: AppServices.firestore
          .collection('collabRequests')
          .where('farmId', isEqualTo: userFarmId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests.'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final requestId = requests[index].id;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('Request from: ${data['requesterId']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _approveRequest(requestId),
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _rejectRequest(requestId),
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyCollaborationsTab() {
    final uid = _currentUserId;
    if (uid == null) {
      return const EmptyView(
        message: 'Sign in to view your collaborations.',
        icon: Icons.group,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: AppServices.firestore
          .collection('collabRequests')
          .where('requesterId', isEqualTo: uid)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const Center(child: Text('No collaborations yet.'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            final farmId = data['farmId'];

            return FutureBuilder<DocumentSnapshot>(
              future:
                  AppServices.firestore.collection('farms').doc(farmId).get(),
              builder: (context, farmSnapshot) {
                if (!farmSnapshot.hasData || !farmSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final farm =
                    farmSnapshot.data!.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: AppImage(
                      source: farm['imageUrl']?.toString(),
                      width: 60,
                      height: 60,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(_farmTitle(farm)),
                    subtitle: Text('Owner: ${farm['owner'] ?? 'Unknown'}'),
                    trailing: TextButton(
                      onPressed: () => _endCollaboration(request.id),
                      child: const Text(
                        'End',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farm Collaboration')),
        body: const EmptyView(
          message: 'Sign in to use farm collaboration.',
          icon: Icons.group_off,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Collaboration'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Apply Requests'),
            Tab(text: 'Pending Requests'),
            Tab(text: 'My Collaborations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplyRequestsTab(),
          _buildPendingRequestsTab(),
          _buildMyCollaborationsTab(),
        ],
      ),
    );
  }
}
