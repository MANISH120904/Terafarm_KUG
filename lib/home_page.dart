import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'menu_page.dart';
import 'product_page.dart';
import 'services/app_services.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/app_image.dart';
import 'widgets/notifications_sheet.dart';
import 'widgets/state_views.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> categories = const [
    {'name': 'Onion', 'image': 'assets/onion.png'},
    {'name': 'Tomato', 'image': 'assets/tomato.png'},
    {'name': 'Beans', 'image': 'assets/beans.png'},
    {'name': 'Greens', 'image': 'assets/greens.png'},
  ];

  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFarmSelected(DocumentSnapshot farmDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductPage(farmId: farmDoc.id)),
    );
  }

  bool _matchesFilters(Map<String, dynamic> farm) {
    final name = (farm['farmName'] ?? farm['name'] ?? '').toString().toLowerCase();
    final description =
        (farm['farmDescription'] ?? '').toString().toLowerCase();
    final products = (farm['products'] as List?) ?? [];
    final cropNames = products
        .map((p) => (p is Map ? p['cropName'] : null)?.toString().toLowerCase() ?? '')
        .toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final hit = name.contains(q) ||
          description.contains(q) ||
          cropNames.any((c) => c.contains(q));
      if (!hit) return false;
    }

    if (_selectedCategory != null) {
      final cat = _selectedCategory!.toLowerCase();
      if (!cropNames.any((c) => c.contains(cat))) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
      drawer: const MenuPage(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search farms or crops',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Eat what makes you healthy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.map((category) {
                  final selected = _selectedCategory == category['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory =
                            selected ? null : category['name'];
                      });
                    },
                    child: Container(
                      width: 76,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.green.shade50
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? Colors.green.shade700
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(category['image']!, width: 40, height: 40),
                          const SizedBox(height: 4),
                          Text(
                            category['name']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Farms around you',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: _selectedCategory != null
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ListTile(
                                title: Text(
                                  'Filter by crop',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ListTile(
                                title: const Text('All farms'),
                                trailing: _selectedCategory == null
                                    ? const Icon(Icons.check)
                                    : null,
                                onTap: () {
                                  setState(() => _selectedCategory = null);
                                  Navigator.pop(context);
                                },
                              ),
                              ...categories.map(
                                (c) => ListTile(
                                  leading: Image.asset(c['image']!, width: 28),
                                  title: Text(c['name']!),
                                  trailing: _selectedCategory == c['name']
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () {
                                    setState(
                                      () => _selectedCategory = c['name'],
                                    );
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            StreamBuilder<QuerySnapshot>(
              stream: AppServices.firestore
                  .collection('farms')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: LoadingView(),
                  );
                }
                if (snapshot.hasError) {
                  return ErrorView(
                    message: 'Could not load farms: ${snapshot.error}',
                  );
                }
                final farmDocs = (snapshot.data?.docs ?? [])
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _matchesFilters(data);
                    })
                    .toList();

                if (farmDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: EmptyView(
                      message: 'No farms match your search.',
                      icon: Icons.agriculture,
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: farmDocs.length,
                  itemBuilder: (context, index) {
                    final farm =
                        farmDocs[index].data() as Map<String, dynamic>;
                    final farmName = farm['farmName'] ?? 'Unnamed Farm';
                    final description =
                        farm['farmDescription'] ?? 'No description';
                    final imageUrl =
                        farm['imageUrl']?.toString() ?? 'assets/sample_farm.png';
                    final scale = farm['scale'] ?? 'N/A';
                    final rating = farm['rating'] ?? 4.0;

                    return GestureDetector(
                      onTap: () => _onFarmSelected(farmDocs[index]),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppImage(
                              source: imageUrl,
                              height: 150,
                              width: double.infinity,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    farmName.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    description.toString(),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Scale: $scale'),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.orange,
                                            size: 16,
                                          ),
                                          Text(rating.toString()),
                                        ],
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
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}
