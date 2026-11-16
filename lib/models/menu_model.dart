import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Representasi model item katalog menu dan stok pada koleksi Firestore `menus`.
@immutable
class MenuModel {
  final String menuId;
  final String name;
  final String category;
  final int price;
  final int stock;
  final int minStock;
  final String? imageUrl;
  final DateTime updatedAt;

  const MenuModel({
    required this.menuId,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.minStock,
    this.imageUrl,
    required this.updatedAt,
  });

  /// Bernilai true apabila stok masih tersedia (> 0) namun <= batas minimum.
  bool get isLowStock => stock > 0 && stock <= minStock;

  /// Bernilai true apabila stok habis (<= 0).
  bool get isOutOfStock => stock <= 0;

  /// Bernilai true apabila menu tersedia untuk dipesan (> 0).
  bool get isAvailable => stock > 0;

  /// Alias kompatibilitas skema berbahasa Indonesia.
  String get nama => name;
  String get kategori => category;
  int get harga => price;
  int get stok => stock;
  int get batasMinimum => minStock;

  /// Membuat instance [MenuModel] dari map JSON/Firestore.
  factory MenuModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return MenuModel(
      menuId: (documentId ?? map['menuId'] ?? map['menu_id'] ?? '') as String,
      name: (map['name'] ?? map['nama'] ?? '') as String,
      category: (map['category'] ?? map['kategori'] ?? '') as String,
      price: _parseInt(map['price'] ?? map['harga']),
      stock: _parseInt(map['stock'] ?? map['stok']),
      minStock: _parseInt(
        map['minStock'] ?? map['batasMinimum'] ?? map['batas_minimum'],
      ),
      imageUrl: (map['imageUrl'] ?? map['image_url']) as String?,
      updatedAt: _parseDateTime(map['updatedAt'] ?? map['updated_at']),
    );
  }

  /// Membuat instance [MenuModel] langsung dari [DocumentSnapshot] Firestore.
  factory MenuModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return MenuModel.fromMap(data, documentId: doc.id);
  }

  /// Mengonversi objek [MenuModel] menjadi map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'menuId': menuId,
      'name': name,
      'nama': name,
      'category': category,
      'kategori': category,
      'price': price,
      'harga': price,
      'stock': stock,
      'stok': stock,
      'minStock': minStock,
      'batasMinimum': minStock,
      'imageUrl': imageUrl,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Mengembalikan salinan baru [MenuModel] dengan nilai field yang diperbarui.
  MenuModel copyWith({
    String? menuId,
    String? name,
    String? category,
    int? price,
    int? stock,
    int? minStock,
    String? imageUrl,
    bool clearImageUrl = false,
    DateTime? updatedAt,
  }) {
    return MenuModel(
      menuId: menuId ?? this.menuId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
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
    return other is MenuModel &&
        other.menuId == menuId &&
        other.name == name &&
        other.category == category &&
        other.price == price &&
        other.stock == stock &&
        other.minStock == minStock &&
        other.imageUrl == imageUrl &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    menuId,
    name,
    category,
    price,
    stock,
    minStock,
    imageUrl,
    updatedAt,
  );
}
