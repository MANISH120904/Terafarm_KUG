import 'package:TeraFarm/demo/demo_seed.dart';
import 'package:TeraFarm/home_page.dart';
import 'package:TeraFarm/login_page.dart';
import 'package:TeraFarm/main.dart';
import 'package:TeraFarm/my_orders_page.dart';
import 'package:TeraFarm/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppServices.init();
  });

  setUp(() async {
    AppServices.cart.clear();
    await AppServices.signOut();
  });

  testWidgets('app boots to landing in demo mode', (tester) async {
    await tester.pumpWidget(const TeraFarmApp());
    await tester.pump();
    expect(find.textContaining('Terafarm'), findsWidgets);
    expect(find.text('Get Started'), findsOneWidget);
    // Cancel pending landing redirect timer.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('DEV login reaches home with seeded farms', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AppServices.cart,
        child: MaterialApp(
          home: const LoginPage(),
          theme: ThemeData(useMaterial3: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Continue as Demo Farmer'), findsOneWidget);
    await tester.tap(find.textContaining('Continue as Demo Farmer'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // After login, LoginPage navigates to HomePage
    expect(find.text('Farms around you'), findsOneWidget);
    expect(find.textContaining('Green Terrace'), findsWidgets);
  });

  testWidgets('logout returns to login', (tester) async {
    await AppServices.signInAsDemoUser();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AppServices.cart,
        child: MaterialApp(
          home: const HomePage(),
          theme: ThemeData(useMaterial3: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await AppServices.signOut();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AppServices.cart,
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);
  });

  test('seed data is internally consistent', () async {
    final farms = await AppServices.firestore.collection('farms').get();
    final users = await AppServices.firestore.collection('users').get();
    final orders = await AppServices.firestore.collection('orders').get();

    final userIds = users.docs.map((d) => d.id).toSet();
    expect(userIds.contains(DemoSeed.demoUid), isTrue);
    expect(farms.docs, isNotEmpty);
    expect(orders.docs, isNotEmpty);

    for (final farm in farms.docs) {
      final sellerId = farm.data()['sellerId']?.toString();
      expect(sellerId, isNotNull);
      expect(userIds.contains(sellerId), isTrue, reason: 'farm ${farm.id}');
    }

    for (final order in orders.docs) {
      final data = order.data();
      expect(userIds.contains(data['buyerId']), isTrue);
      expect(userIds.contains(data['sellerId']), isTrue);
      expect(data['deliveryMethod'] ?? data['delivery'], isNotNull);
    }
  });

  test('checkout creates order visible to buyer', () async {
    await AppServices.signInAsDemoUser();
    AppServices.cart.clear();
    AppServices.cart.addItem({
      'name': 'Tomato',
      'price': 40,
      'quantity': 1,
      'image': 'assets/tomato.png',
      'unit': '500 gms',
      'sellerId': 'user-priya',
    });

    final before = await AppServices.firestore
        .collection('orders')
        .where('buyerId', isEqualTo: DemoSeed.demoUid)
        .get();

    await AppServices.firestore.collection('orders').add({
      'cartItems': AppServices.cart.items,
      'deliveryMethod': 'delivery',
      'delivery': 'delivery',
      'location': AppServices.cart.deliveryAddress,
      'itemTotal': AppServices.cart.itemTotal,
      'deliveryFee': 30,
      'totalPayable': AppServices.cart.itemTotal + 30,
      'status': 'pending',
      'orderDate': DateTime.now().toIso8601String(),
      'buyerId': DemoSeed.demoUid,
      'sellerId': 'user-priya',
    });
    AppServices.cart.clear();

    final after = await AppServices.firestore
        .collection('orders')
        .where('buyerId', isEqualTo: DemoSeed.demoUid)
        .get();
    expect(after.docs.length, greaterThan(before.docs.length));
  });

  test('seller can accept pending order', () async {
    await AppServices.signInAsDemoUser();
    final pending = await AppServices.firestore
        .collection('orders')
        .where('sellerId', isEqualTo: DemoSeed.demoUid)
        .where('status', isEqualTo: 'pending')
        .get();
    expect(pending.docs, isNotEmpty);
    final doc = pending.docs.first;
    await doc.reference.update({'status': 'accepted'});
    final updated = await doc.reference.get();
    expect(updated.data()?['status'], 'accepted');
    await doc.reference.update({'status': 'pending'});
  });

  testWidgets('MyOrdersPage renders for demo user', (tester) async {
    await AppServices.signInAsDemoUser();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AppServices.cart,
        child: const MaterialApp(home: MyOrdersPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My Orders'), findsOneWidget);
  });
}
