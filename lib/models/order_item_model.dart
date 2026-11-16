import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Representasi item pesanan yang menyimpan snapshot nama dan harga saat checkout.
@immutable
class OrderItemModel {
  final String menuId;
  final String name;
  final int qty;
  final int price;

  const OrderItemModel({
    required this.menuId,
    required this.name,
    required this.qty,
    required this.price,
  });

  /// Menghitung subtotal item (qty * price).
  int get subtotal => qty * price;

  /// Alias kompatibilitas skema snapshot transaksi.
  String get namaMenuSnapshot => name;
  int get hargaSatuanSnapshot => price;

  /// Membuat instance [OrderItemModel] dari map JSON/Firestore.
  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      menuId: (map['menuId'] ?? map['menu_id'] ?? '') as String,
      name:
          (map['name'] ??
                  map['nama'] ??
                  map['namaMenuSnapshot'] ??
                  map['nama_menu_snapshot'] ??
                  '')
              as String,
      qty: _parseInt(map['qty']),
      price: _parseInt(
        map['price'] ??
            map['harga'] ??
            map['hargaSatuanSnapshot'] ??
            map['harga_satuan_snapshot'],
      ),
    );
  }

  /// Membuat instance [OrderItemModel] langsung dari [DocumentSnapshot] Firestore.
  factory OrderItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return OrderItemModel.fromMap(data);
  }

  /// Mengonversi objek [OrderItemModel] menjadi map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'menuId': menuId,
      'name': name,
      'nama': name,
      'qty': qty,
      'price': price,
      'harga': price,
      'subtotal': subtotal,
    };
  }

  /// Mengembalikan salinan baru [OrderItemModel] dengan nilai field yang diperbarui.
  OrderItemModel copyWith({
    String? menuId,
    String? name,
    int? qty,
    int? price,
  }) {
    return OrderItemModel(
      menuId: menuId ?? this.menuId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      price: price ?? this.price,
    );
  }

  static int _parseInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw) ?? 0;
    }
    return 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItemModel &&
        other.menuId == menuId &&
        other.name == name &&
        other.qty == qty &&
        other.price == price;
  }

  @override
  int get hashCode => Object.hash(menuId, name, qty, price);
}
