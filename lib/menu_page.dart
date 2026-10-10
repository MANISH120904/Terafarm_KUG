import 'package:flutter/material.dart';

import 'account_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'my_orders_page.dart';
import 'services/app_services.dart';
import 'widgets/app_image.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  Future<Map<String, String>> _fetchUserData() async {
    final user = AppServices.auth.currentUser;
    if (user == null) {
      return {'username': 'Guest', 'profileImage': '', 'email': ''};
    }
    final doc =
        await AppServices.firestore.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    return {
      'username': data['username']?.toString() ?? 'User',
      'profileImage': data['profileImage']?.toString() ?? '',
      'email': user.email ?? data['email']?.toString() ?? '',
    };
  }

  Future<void> _logout(BuildContext context) async {
    await AppServices.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, String>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          final data = snapshot.data ??
              {'username': '…', 'profileImage': '', 'email': ''};
          final profileImage = data['profileImage'] ?? '';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.green.shade900),
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      profileImage.isNotEmpty
                          ? ClipOval(
                              child: AppImage(
                                source: profileImage,
                                width: 48,
                                height: 48,
                                fallbackAsset: 'assets/Boy1.png',
                              ),
                            )
                          : const Icon(
                              Icons.account_circle,
                              size: 48,
                              color: Colors.white,
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['username'] ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              data['email'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Account'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: const Text('My orders'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyOrdersPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.agriculture),
                title: const Text('Farm dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardPage()),
                  );
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Log out',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 245, 120, 11),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
