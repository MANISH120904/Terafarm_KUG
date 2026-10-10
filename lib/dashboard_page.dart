import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'add_product_page.dart';
import 'ai_page.dart';
import 'edit_farm_page.dart';
import 'list_farm_page.dart';
import 'menu_page.dart';
import 'order_list_page.dart';
import 'services/app_services.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/notifications_sheet.dart';
import 'widgets/state_views.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const int _navIndex = 2;

  double _computeEarnings(List<QueryDocumentSnapshot> orders) {
    var total = 0.0;
    for (final doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['status'] ?? '').toString().toLowerCase() != 'delivered') {
        continue;
      }
      final amount = data['totalAmount'] ?? data['total'] ?? data['amount'];
      if (amount is num) {
        total += amount.toDouble();
      } else {
        final cartItems = data['cartItems'] as List?;
        if (cartItems != null) {
          for (final raw in cartItems) {
            if (raw is! Map) continue;
            final price = (raw['price'] as num?)?.toDouble() ?? 0;
            final qty = (raw['quantity'] as num?)?.toInt() ?? 1;
            total += price * qty;
          }
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final user = AppServices.auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green.shade900,
          title: const Text('Farm Dashboard'),
        ),
        body: const EmptyView(
          message: 'Sign in to view your farm dashboard.',
          icon: Icons.agriculture,
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: _navIndex),
      );
    }

    final sellerId = user.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      bottomNavigationBar: const AppBottomNav(currentIndex: _navIndex),
      floatingActionButton: _buildFloatingActionButton(),
      body: _buildBody(sellerId),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.green.shade900,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
      ),
      title: Row(
        children: [
          Transform.translate(
            offset: const Offset(-40, 5),
            child: Image.asset("assets/terafarm_logo.png", height: 40),
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
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: MenuPage(),
      ),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: Colors.blue.shade900, // Changed to dark blue
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AIPage(),
          ), // Navigate to AIPage
        );
      },
      child: const Icon(
        Icons.smart_toy,
        color: Colors.white,
        size: 28,
      ), // AI icon
    );
  }

  Widget _buildBody(String sellerId) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: AppServices.firestore
            .collection('orders')
            .where('sellerId', isEqualTo: sellerId)
            .snapshots(),
        builder: (context, orderSnapshot) {
          final orders = orderSnapshot.data?.docs ?? [];
          final earnings = _computeEarnings(orders);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildDashboardHeader(),
                const SizedBox(height: 20),
                _buildBarChart(sellerId),
                _buildEarningsSection(earnings),
                _buildPlantGrowthAnalysis(),
                _buildDailyTaskSection(),
                _buildDashboardButtons(),
                _buildFarmSection(sellerId),
                _buildProductListingsTable(sellerId),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        "Farm Dashboard", // Updated title
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEarningsSection(double earnings) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          'Total Earnings: Rs.${earnings.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBarChart(String sellerId) {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

    return StreamBuilder<QuerySnapshot>(
      stream:
          AppServices.firestore
              .collection('orders')
              .where('sellerId', isEqualTo: sellerId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text("Error: ${snapshot.error}")),
          );
        }
        if (!snapshot.hasData) {
          return SizedBox(
            height: 200,
            child: const Center(child: Text("No Data")),
          );
        }

        final allOrders = snapshot.data!.docs;
        final filteredOrders =
            allOrders.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final orderDateRaw = data['orderDate'];
              DateTime? date;
              if (orderDateRaw is Timestamp) {
                date = orderDateRaw.toDate();
              } else if (orderDateRaw is String) {
                try {
                  date = DateTime.parse(orderDateRaw);
                } catch (e) {
                  date = null;
                }
              }
              if (date == null) return false;
              // Use inclusive checks to include orders on the boundary dates
              return !date.isBefore(startOfMonth) && !date.isAfter(endOfMonth);
            }).toList();

        Map<int, int> ordersPerDay = {
          for (int day = 1; day <= endOfMonth.day; day++) day: 0,
        };

        for (var order in filteredOrders) {
          final data = order.data() as Map<String, dynamic>;
          final orderDateRaw = data['orderDate'];
          DateTime? date;
          if (orderDateRaw is Timestamp) {
            date = orderDateRaw.toDate();
          } else if (orderDateRaw is String) {
            try {
              date = DateTime.parse(orderDateRaw);
            } catch (e) {
              date = null;
            }
          }
          if (date != null) {
            ordersPerDay[date.day] = (ordersPerDay[date.day] ?? 0) + 1;
          }
        }

        List<BarChartGroupData> barGroups =
            ordersPerDay.entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(),
                    color: Colors.blue, // Changed to dark blue
                    width: 12, // Reduced bar width to create spacing
                    borderRadius: BorderRadius.circular(
                      4,
                    ), // Slightly curved edges
                  ),
                ],
              );
            }).toList();

        return Container(
          height: 200, // Box height remains the same
          padding: const EdgeInsets.all(10), // Simplified padding
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.green.shade800,
              width: 1.5,
            ), // Slightly thinner border
            borderRadius: BorderRadius.circular(
              8,
            ), // Slightly smaller rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 30.0,
            ), // Added padding to move the graph slightly down
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                barTouchData: BarTouchData(enabled: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1, // Set Y-axis scale to 1
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1, // Match the scale of the left Y-axis
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize:
                          50, // Increased reserved size for visibility
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 != 0) {
                          return const SizedBox(); // Show labels for even values only
                        }
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                          ), // Adjusted padding
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    // Disable the upper x-axis
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                groupsSpace: 8, // Added spacing between bar groups
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlantGrowthAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Plant Growth Analysis",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset("assets/tomato.png", height: 50),
            Image.asset("assets/beans.png", height: 50),
            Image.asset("assets/onion.png", height: 50),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyTaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Daily Task",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Watering",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ), // Increased size and made bold
              ),
              Row(
                children: [
                  Column(
                    children: [
                      const Text("At 8:30 AM"),
                      Checkbox(value: false, onChanged: (value) {}),
                    ],
                  ),
                  const SizedBox(
                    width: 20,
                  ), // Added space between the two columns
                  Column(
                    children: [
                      const Text("At 5:30 PM"),
                      Checkbox(value: false, onChanged: (value) {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardButtons() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                _buildDashboardButton("List a Farm", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ListFarmPage()),
                  );
                }, Colors.orange), // Changed to orange
                const SizedBox(height: 10),
                _buildDashboardButton("List a Produce", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProductPage()),
                  );
                }, Colors.orange), // Changed to orange
                const SizedBox(height: 10),
                _buildDashboardButton("Orders", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderListPage()),
                  );
                }, Colors.orange), // Changed to orange
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFarmSection(String sellerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Your Farm",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Center(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                AppServices.firestore
                    .collection('farms')
                    .where('sellerId', isEqualTo: sellerId)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final farms = snapshot.data!.docs;
              if (farms.isEmpty) {
                return const Text("No farm registered by you.");
              }

              final farm = farms.first;
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditFarmPage(farmId: farm.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Changed to orange
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      farm['farmName'] ?? "Your Farm",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.edit, color: Colors.white),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductListingsTable(String sellerId) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 300,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.shade800),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Product Listings",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              StreamBuilder<QuerySnapshot>(
                stream:
                    AppServices.firestore
                        .collection('farms')
                        .where('sellerId', isEqualTo: sellerId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final farmDocs = snapshot.data!.docs;
                  if (farmDocs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("No products found."),
                    );
                  }

                  final List<DataRow> allRows = [];
                  int rowIndex = 1;
                  for (var doc in farmDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final products = data['products'] as List? ?? [];
                    for (int i = 0; i < products.length; i++) {
                      final product = products[i] as Map<String, dynamic>;
                      final cropName = product['cropName'] ?? 'N/A';
                      final stock = product['stock in kgs'] ?? '0';
                      final price = product['pricePerKg'] ?? 'N/A';

                      allRows.add(
                        DataRow(
                          cells: [
                            DataCell(Text(rowIndex.toString())),
                            DataCell(Text(cropName)),
                            DataCell(Text("$stock Kg")),
                            DataCell(Text("Rs. $price")),
                          ],
                        ),
                      );
                      rowIndex++;
                    }
                  }

                  if (allRows.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("No products found."),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("#")),
                        DataColumn(label: Text("Crop")),
                        DataColumn(label: Text("Stock")),
                        DataColumn(label: Text("Price per Kg")),
                      ],
                      rows: allRows,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(children: [const SizedBox(height: 20)]);
  }

  Widget _buildDashboardButton(
    String text,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // Use the passed color
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
