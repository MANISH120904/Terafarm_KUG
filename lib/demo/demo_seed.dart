import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

/// Deterministic sample data for demo walkthroughs.
class DemoSeed {
  DemoSeed._();

  static const String demoUid = 'demo-farmer-001';
  static const String demoEmail = 'demo@terafarm.app';
  static const String demoPassword = 'demo1234';
  static const String demoDisplayName = 'Arjun Mehta';

  static MockUser get demoMockUser => MockUser(
        isAnonymous: false,
        uid: demoUid,
        email: demoEmail,
        displayName: demoDisplayName,
      );

  static Future<void> seed(FirebaseFirestore firestore) async {
    // Users
    final users = <String, Map<String, dynamic>>{
      demoUid: {
        'uid': demoUid,
        'username': demoDisplayName,
        'email': demoEmail,
        'phone': '+91 98765 43210',
        'locality': 'Indiranagar, Bengaluru',
        'profileImage': 'assets/Boy1.png',
        'role': 'Buyer / Seller',
        'level': 20,
        'points': 80,
      },
      'user-priya': {
        'uid': 'user-priya',
        'username': 'Priya Sharma',
        'email': 'priya@example.com',
        'phone': '+91 98111 22334',
        'locality': 'Koramangala, Bengaluru',
        'profileImage': 'assets/Girl1.png',
      },
      'user-rahul': {
        'uid': 'user-rahul',
        'username': 'Rahul Verma',
        'email': 'rahul@example.com',
        'phone': '+91 98222 33445',
        'locality': 'HSR Layout, Bengaluru',
        'profileImage': 'assets/Boy2.png',
      },
      'user-meera': {
        'uid': 'user-meera',
        'username': 'Meera Iyer',
        'email': 'meera@example.com',
        'phone': '+91 98333 44556',
        'locality': 'Jayanagar, Bengaluru',
        'profileImage': 'assets/Girl2.png',
      },
      'user-vikram': {
        'uid': 'user-vikram',
        'username': 'Vikram Singh',
        'email': 'vikram@example.com',
        'phone': '+91 98444 55667',
        'locality': 'Whitefield, Bengaluru',
        'profileImage': 'assets/Boy3.png',
      },
      'user-ananya': {
        'uid': 'user-ananya',
        'username': 'Ananya Reddy',
        'email': 'ananya@example.com',
        'phone': '+91 98555 66778',
        'locality': 'Madhapur, Hyderabad',
        'profileImage': 'assets/Girl3.png',
      },
      'user-karan': {
        'uid': 'user-karan',
        'username': 'Karan Patel',
        'email': 'karan@example.com',
        'phone': '+91 98666 77889',
        'locality': 'Andheri, Mumbai',
        'profileImage': 'assets/Boy4.png',
      },
    };

    for (final entry in users.entries) {
      await firestore.collection('users').doc(entry.key).set(entry.value);
    }

    // Farms
    final now = DateTime.now();
    final farms = <String, Map<String, dynamic>>{
      'farm-arjun': {
        'farmName': 'Green Terrace Farms',
        'name': 'Green Terrace Farms',
        'contactNumber': '+91 98765 43210',
        'location': 'Indiranagar, Bengaluru',
        'farmDescription':
            'Rooftop farm growing organic vegetables for the neighbourhood.',
        'scale': 'Small Scale',
        'imageUrl': 'assets/sample_farm.png',
        'sellerId': demoUid,
        'owner': demoDisplayName,
        'rating': 4.7,
        'distanceCharge': 20,
        'isReadyToCollab': true,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'products': [
          {'cropName': 'Tomato', 'stock in kgs': '25', 'pricePerKg': '40'},
          {'cropName': 'Onion', 'stock in kgs': '40', 'pricePerKg': '30'},
          {'cropName': 'Greens', 'stock in kgs': '15', 'pricePerKg': '35'},
        ],
      },
      'farm-priya': {
        'farmName': 'Skyline Greens',
        'name': 'Skyline Greens',
        'contactNumber': '+91 98111 22334',
        'location': 'Koramangala, Bengaluru',
        'farmDescription': 'Vertical grow bags and hydroponic herbs.',
        'scale': 'Small Scale',
        'imageUrl': 'assets/sample_farm2.png',
        'sellerId': 'user-priya',
        'owner': 'Priya Sharma',
        'rating': 4.5,
        'distanceCharge': 25,
        'isReadyToCollab': true,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'products': [
          {'cropName': 'Beans', 'stock in kgs': '12', 'pricePerKg': '55'},
          {'cropName': 'Greens', 'stock in kgs': '20', 'pricePerKg': '32'},
        ],
      },
      'farm-rahul': {
        'farmName': 'HSR Harvest Hub',
        'name': 'HSR Harvest Hub',
        'contactNumber': '+91 98222 33445',
        'location': 'HSR Layout, Bengaluru',
        'farmDescription': 'Community terrace producing fruits and salad greens.',
        'scale': 'Large Scale',
        'imageUrl': 'assets/sample_farm.png',
        'sellerId': 'user-rahul',
        'owner': 'Rahul Verma',
        'rating': 4.2,
        'distanceCharge': 30,
        'isReadyToCollab': false,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 8))),
        'products': [
          {'cropName': 'Apple', 'stock in kgs': '18', 'pricePerKg': '90'},
          {'cropName': 'Tomato', 'stock in kgs': '30', 'pricePerKg': '38'},
        ],
      },
      'farm-meera': {
        'farmName': 'Jayanagar Leaf Lab',
        'name': 'Jayanagar Leaf Lab',
        'contactNumber': '+91 98333 44556',
        'location': 'Jayanagar, Bengaluru',
        'farmDescription': 'Shade-grown leafy greens and microgreens.',
        'scale': 'Small Scale',
        'imageUrl': 'assets/sample_farm2.png',
        'sellerId': 'user-meera',
        'owner': 'Meera Iyer',
        'rating': 4.8,
        'distanceCharge': 15,
        'isReadyToCollab': true,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'products': [
          {'cropName': 'Greens', 'stock in kgs': '22', 'pricePerKg': '28'},
          {'cropName': 'Beans', 'stock in kgs': '8', 'pricePerKg': '50'},
        ],
      },
      'farm-vikram': {
        'farmName': 'Whitefield Orchard',
        'name': 'Whitefield Orchard',
        'contactNumber': '+91 98444 55667',
        'location': 'Whitefield, Bengaluru',
        'farmDescription': 'Grapes and seasonal veggies on a shared terrace.',
        'scale': 'Large Scale',
        'imageUrl': 'assets/sample_farm.png',
        'sellerId': 'user-vikram',
        'owner': 'Vikram Singh',
        'rating': 4.0,
        'distanceCharge': 35,
        'isReadyToCollab': true,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 12))),
        'products': [
          {'cropName': 'Grape', 'stock in kgs': '10', 'pricePerKg': '120'},
          {'cropName': 'Onion', 'stock in kgs': '50', 'pricePerKg': '28'},
        ],
      },
      'farm-ananya': {
        'farmName': 'Hyderabad Nest Farm',
        'name': 'Hyderabad Nest Farm',
        'contactNumber': '+91 98555 66778',
        'location': 'Madhapur, Hyderabad',
        'farmDescription': 'Balcony tomatoes and kitchen herbs.',
        'scale': 'Small Scale',
        'imageUrl': 'assets/sample_farm2.png',
        'sellerId': 'user-ananya',
        'owner': 'Ananya Reddy',
        'rating': 4.6,
        'distanceCharge': 40,
        'isReadyToCollab': false,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'products': [
          {'cropName': 'Tomato', 'stock in kgs': '14', 'pricePerKg': '42'},
          {'cropName': 'Onion', 'stock in kgs': '20', 'pricePerKg': '32'},
        ],
      },
    };

    for (final entry in farms.entries) {
      await firestore.collection('farms').doc(entry.key).set(entry.value);
    }

    // Orders — demo user as seller and buyer
    final orders = <String, Map<String, dynamic>>{
      'order-pending': {
        'cartItems': [
          {
            'name': 'Tomato',
            'price': 40,
            'quantity': 2,
            'image': 'assets/tomato.png',
            'unit': '500 gms',
            'sellerId': demoUid,
          },
        ],
        'deliveryMethod': 'delivery',
        'delivery': 'delivery',
        'location': 'Koramangala, Bengaluru',
        'itemTotal': 80,
        'deliveryFee': 30,
        'totalPayable': 110,
        'status': 'pending',
        'orderDate': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'buyerId': 'user-priya',
        'sellerId': demoUid,
      },
      'order-accepted': {
        'cartItems': [
          {
            'name': 'Onion',
            'price': 30,
            'quantity': 3,
            'image': 'assets/onion.png',
            'unit': '500 gms',
            'sellerId': demoUid,
          },
        ],
        'deliveryMethod': 'pickup',
        'delivery': 'pickup',
        'location': 'Indiranagar, Bengaluru',
        'itemTotal': 90,
        'deliveryFee': 0,
        'totalPayable': 90,
        'status': 'accepted',
        'orderDate': now.subtract(const Duration(days: 1)).toIso8601String(),
        'buyerId': 'user-rahul',
        'sellerId': demoUid,
      },
      'order-delivered': {
        'cartItems': [
          {
            'name': 'Greens',
            'price': 35,
            'quantity': 4,
            'image': 'assets/greens.png',
            'unit': '500 gms',
            'sellerId': demoUid,
          },
        ],
        'deliveryMethod': 'delivery',
        'delivery': 'delivery',
        'location': 'HSR Layout, Bengaluru',
        'itemTotal': 140,
        'deliveryFee': 30,
        'totalPayable': 170,
        'status': 'delivered',
        'orderDate': now.subtract(const Duration(days: 3)).toIso8601String(),
        'buyerId': 'user-meera',
        'sellerId': demoUid,
      },
      'order-buyer': {
        'cartItems': [
          {
            'name': 'Beans',
            'price': 55,
            'quantity': 2,
            'image': 'assets/beans.png',
            'unit': '500 gms',
            'sellerId': 'user-priya',
          },
        ],
        'deliveryMethod': 'delivery',
        'delivery': 'delivery',
        'location': 'Indiranagar, Bengaluru',
        'itemTotal': 110,
        'deliveryFee': 30,
        'totalPayable': 140,
        'status': 'accepted',
        'orderDate': now.subtract(const Duration(days: 2)).toIso8601String(),
        'buyerId': demoUid,
        'sellerId': 'user-priya',
      },
      'order-cancelled': {
        'cartItems': [
          {
            'name': 'Tomato',
            'price': 40,
            'quantity': 1,
            'image': 'assets/tomato.png',
            'unit': '500 gms',
            'sellerId': demoUid,
          },
        ],
        'deliveryMethod': 'delivery',
        'delivery': 'delivery',
        'location': 'Whitefield, Bengaluru',
        'itemTotal': 40,
        'deliveryFee': 30,
        'totalPayable': 70,
        'status': 'cancelled',
        'orderDate': now.subtract(const Duration(days: 6)).toIso8601String(),
        'buyerId': 'user-vikram',
        'sellerId': demoUid,
      },
    };

    for (final entry in orders.entries) {
      await firestore.collection('orders').doc(entry.key).set(entry.value);
    }

    // Top-level products (legacy collection kept for compatibility)
    await firestore.collection('products').doc('prod-tomato').set({
      'name': 'Cherry Tomato Pack',
      'price': 45.0,
      'category': 'Vegetables',
      'description': 'Fresh cherry tomatoes from Green Terrace Farms.',
      'sellerId': demoUid,
      'timestamp': Timestamp.fromDate(now),
    });

    // Collab requests
    await firestore.collection('collabRequests').doc('collab-1').set({
      'farmId': 'farm-priya',
      'requesterId': demoUid,
      'status': 'pending',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 8))),
    });
    await firestore.collection('collabRequests').doc('collab-2').set({
      'farmId': 'farm-arjun',
      'requesterId': 'user-meera',
      'status': 'approved',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
    });

    // Groups
    await firestore.collection('groups').doc('group-urban').set({
      'name': 'Urban Growers Bengaluru',
      'description': 'Tips, swaps, and meetups for terrace farmers.',
      'profileUrl': 'assets/sample_farm.png',
      'isPublic': true,
      'createdBy': demoUid,
      'members': [demoUid, 'user-priya', 'user-rahul', 'user-meera'],
      'admins': [demoUid],
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
    });
    await firestore.collection('groups').doc('group-compost').set({
      'name': 'Compost Collective',
      'description': 'Share composting recipes and worm-bin wins.',
      'profileUrl': 'assets/sample_farm2.png',
      'isPublic': true,
      'createdBy': 'user-priya',
      'members': [demoUid, 'user-priya', 'user-ananya'],
      'admins': ['user-priya'],
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 20))),
    });

    await firestore
        .collection('groups')
        .doc('group-urban')
        .collection('messages')
        .doc('msg-1')
        .set({
      'text': 'Welcome everyone! What are you planting this week?',
      'senderId': demoUid,
      'sentAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
    });
    await firestore
        .collection('groups')
        .doc('group-urban')
        .collection('messages')
        .doc('msg-2')
        .set({
      'text': 'Cherry tomatoes and spinach on my terrace 🌱',
      'senderId': 'user-priya',
      'sentAt': Timestamp.fromDate(now.subtract(const Duration(hours: 20))),
    });

    // Channels
    await firestore.collection('channels').doc('channel-tips').set({
      'name': 'Seasonal Tips',
      'description': 'Month-by-month growing advice for Indian cities.',
      'profileUrl': 'assets/greens.png',
      'isPublic': true,
      'createdBy': demoUid,
      'members': [demoUid, 'user-priya', 'user-vikram', 'user-karan'],
      'admins': [demoUid],
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 25))),
    });

    await firestore
        .collection('channels')
        .doc('channel-tips')
        .collection('posts')
        .doc('post-1')
        .set({
      'text':
          'Monsoon tip: raise pots on bricks and ensure drainage holes stay clear.',
      'senderId': demoUid,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
    });

    await firestore
        .collection('channels')
        .doc('channel-tips')
        .collection('posts')
        .doc('post-1')
        .collection('comments')
        .doc('c-1')
        .set({
      'text': 'Thanks! That saved my basil last year.',
      'senderId': 'user-priya',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
    });

    // Notifications
    await firestore.collection('notifications').doc('n-1').set({
      'userId': demoUid,
      'title': 'New order received',
      'body': 'Priya Sharma ordered Tomato (2 × 500 gms).',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
      'read': false,
    });
    await firestore.collection('notifications').doc('n-2').set({
      'userId': demoUid,
      'title': 'Collab request',
      'body': 'Meera Iyer approved your collaboration on Green Terrace Farms.',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      'read': true,
    });
    await firestore.collection('notifications').doc('n-3').set({
      'userId': demoUid,
      'title': 'Community update',
      'body': 'New post in Seasonal Tips channel.',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      'read': false,
    });
  }
}
