import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'edit_profile_page.dart';
import 'leaderboard_page.dart';
import 'login_page.dart';
import 'my_orders_page.dart';
import 'services/app_services.dart';
import 'services/cart_service.dart';
import 'widgets/app_image.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>
    with TickerProviderStateMixin {
  bool _animate = false;

  Future<Map<String, dynamic>> _fetchUserDetails() async {
    final user = AppServices.auth.currentUser;
    if (user == null) return {};
    final userDoc =
        await AppServices.firestore.collection('users').doc(user.uid).get();
    return userDoc.data() ?? {};
  }

  Future<void> _logout(BuildContext context) async {
    await AppServices.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _showAddressDialog(BuildContext context) {
    final cart = context.read<CartService>();
    final controller = TextEditingController(text: cart.deliveryAddress);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('My Address'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Delivery address',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                cart.deliveryAddress = controller.text.trim();
                Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address updated')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile'));
          }

          final userDetails = snapshot.data ?? {};
          final profileImage = userDetails['profileImage']?.toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey.shade200,
                            child: profileImage != null &&
                                    profileImage.isNotEmpty
                                ? ClipOval(
                                    child: AppImage(
                                      source: profileImage,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.person, size: 50),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.orange,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditProfilePage(),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userDetails['username']?.toString() ?? 'User Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Buyer / Seller',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: const Text(
                              'Lvl 20',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                LinearProgressIndicator(
                                  value: 0.8,
                                  backgroundColor: Colors.grey,
                                  color: Colors.blue,
                                  minHeight: 5,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '80/100 pts',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildAnimatedTile(
                  0,
                  _infoTile(
                    Icons.phone,
                    userDetails['phone']?.toString() ?? '+91 00000 00000',
                  ),
                ),
                _buildAnimatedTile(
                  1,
                  _infoTile(
                    Icons.email_outlined,
                    userDetails['email']?.toString() ??
                        AppServices.auth.currentUser?.email ??
                        'example@email.com',
                  ),
                ),
                const SizedBox(height: 20),
                _buildAnimatedTile(
                  2,
                  _menuTile(
                    Icons.favorite_border,
                    'My Orders',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyOrdersPage(),
                        ),
                      );
                    },
                  ),
                ),
                _buildAnimatedTile(
                  3,
                  _menuTile(
                    Icons.local_play_outlined,
                    'Badges',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardPage(),
                        ),
                      );
                    },
                  ),
                ),
                _buildAnimatedTile(
                  4,
                  _menuTile(
                    Icons.location_on_outlined,
                    'My Addresses',
                    onTap: () => _showAddressDialog(context),
                  ),
                ),
                _buildAnimatedTile(
                  5,
                  _menuTile(
                    Icons.list_alt_rounded,
                    'My List',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('My List coming soon')),
                      );
                    },
                  ),
                ),
                _buildAnimatedTile(
                  6,
                  _menuTile(
                    Icons.logout,
                    'Logout',
                    onTap: () => _logout(context),
                    isLogout: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedTile(int index, Widget child) {
    return AnimatedSlide(
      offset: _animate ? Offset.zero : const Offset(0, 0.3),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300 + (index * 100)),
        opacity: _animate ? 1 : 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: child,
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Widget _menuTile(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.orange),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: isLogout ? Colors.red : Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}
