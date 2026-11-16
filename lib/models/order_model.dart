import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'order_item_model.dart';

/// Representasi dokumen transaksi pesanan pada koleksi Firestore `orders`.
@immutable
class OrderModel {
  final String orderId;
  final String tableNumber;
  final String status;
  final int totalPrice;
  final List<OrderItemModel> items;
  final String? cashierId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.orderId,
    required this.tableNumber,
    required this.status,
    required this.totalPrice,
    required this.items,
    this.cashierId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Alias kompatibilitas skema berbahasa Indonesia.
  String get nomorMeja => tableNumber;
  int get totalHarga => totalPrice;
  String? get verifiedByUid => cashierId;
  DateTime get waktuPesan => createdAt;

  /// Membuat instance [OrderModel] dari map JSON/Firestore.
  factory OrderModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final Object? rawItems = map['items'];
    final List<OrderItemModel> parsedItems = <OrderItemModel>[];
    if (rawItems is List) {
      for (final Object? entry in rawItems) {
        if (entry is Map<String, dynamic>) {
          parsedItems.add(OrderItemModel.fromMap(entry));
        } else if (entry is Map) {
          parsedItems.add(
            OrderItemModel.fromMap(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    final DateTime parsedCreatedAt = _parseDateTime(
      map['createdAt'] ?? map['waktuPesan'] ?? map['waktu_pesan'],
    );
    final Object? rawUpdatedAt =
        map['updatedAt'] ?? map['waktuSelesai'] ?? map['waktu_selesai'];

    return OrderModel(
      orderId:
          (documentId ?? map['orderId'] ?? map['order_id'] ?? '') as String,
      tableNumber:
          (map['tableNumber'] ?? map['nomorMeja'] ?? map['nomor_meja'] ?? '')
              as String,
      status: (map['status'] ?? '') as String,
      totalPrice: _parseInt(
        map['totalPrice'] ?? map['totalHarga'] ?? map['total_harga'],
      ),
      items: List<OrderItemModel>.unmodifiable(parsedItems),
      cashierId:
          (map['cashierId'] ?? map['verifiedByUid'] ?? map['verified_by_uid'])
              as String?,
      createdAt: parsedCreatedAt,
      updatedAt: rawUpdatedAt != null
          ? _parseDateTime(rawUpdatedAt)
          : parsedCreatedAt,
    );
  }

  /// Membuat instance [OrderModel] langsung dari [DocumentSnapshot] Firestore.
  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return OrderModel.fromMap(data, documentId: doc.id);
  }

  /// Mengonversi objek [OrderModel] menjadi map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orderId': orderId,
      'tableNumber': tableNumber,
      'nomorMeja': tableNumber,
      'status': status,
      'totalPrice': totalPrice,
      'totalHarga': totalPrice,
      'items': items.map((OrderItemModel item) => item.toMap()).toList(),
      'cashierId': cashierId,
      'verifiedByUid': cashierId,
      'createdAt': Timestamp.fromDate(createdAt),
      'waktuPesan': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Mengembalikan salinan baru [OrderModel] dengan nilai field yang diperbarui.
  OrderModel copyWith({
    String? orderId,
    String? tableNumber,
    String? status,
    int? totalPrice,
    List<OrderItemModel>? items,
    String? cashierId,
    bool clearCashierId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      tableNumber: tableNumber ?? this.tableNumber,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      items: items != null
          ? List<OrderItemModel>.unmodifiable(items)
          : this.items,
      cashierId: clearCashierId ? null : (cashierId ?? this.cashierId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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

  static DateTime _parseDateTime(Object? raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel &&
        other.orderId == orderId &&
        other.tableNumber == tableNumber &&
        other.status == status &&
        other.totalPrice == totalPrice &&
        listEquals(other.items, items) &&
        other.cashierId == cashierId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    orderId,
    tableNumber,
    status,
    totalPrice,
    Object.hashAll(items),
    cashierId,
    createdAt,
    updatedAt,
  );
}
