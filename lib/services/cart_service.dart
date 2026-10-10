import 'package:flutter/foundation.dart';

class CartService extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];
  String deliveryAddress = '4202, T 4, Sultan Street, XYZ City';
  String deliveryWindow = '10 AM - 12 PM';

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int? ?? 1),
      );
  bool get isEmpty => _items.isEmpty;

  void addItem(Map<String, dynamic> item) {
    final name = item['name'] as String? ?? '';
    final existing = _items.indexWhere((e) => e['name'] == name);
    if (existing >= 0) {
      final qty = (_items[existing]['quantity'] as int? ?? 1) +
          (item['quantity'] as int? ?? 1);
      _items[existing] = {..._items[existing], 'quantity': qty};
    } else {
      _items.add(Map<String, dynamic>.from(item));
    }
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= _items.length) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = {..._items[index], 'quantity': quantity};
    }
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  int get itemTotal => _items.fold<int>(0, (sum, item) {
        final price = (item['price'] as num?)?.toInt() ?? 0;
        final qty = (item['quantity'] as int?) ?? 1;
        return sum + price * qty;
      });
}
