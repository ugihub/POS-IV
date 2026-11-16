import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

/// Repositori data untuk mengelola koleksi `menus` di Cloud Firestore.
///
/// Struktur file ini dipisahkan menjadi dua zona pengembangan paralel agar
/// branch Anggota 1 dan Anggota 3 tidak mengalami konflik saat merge ke `main`.
class MenuRepository {
  final FirebaseFirestore _firestore;

  MenuRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referensi koleksi utama `menus` pada Cloud Firestore.
  CollectionReference<Map<String, dynamic>> get menuCollection =>
      _firestore.collection(AppConstants.collectionMenus);

  // ================= AREA KERJA ORANG 1 (STREAM & REGEXP SEARCH) =================
  // Ruang implementasi Anggota 1: stream katalog real-time dan filter pencarian RegExp.
  // Tulis seluruh method baca/stream (watchMenus, searchMenusByRegExp, dll) di area ini.

  // -----------------------------------------------------------------------------
  // Pemisah Zona Kerja (Jangan ubah blok pemisah ini untuk mencegah merge conflict)
  // -----------------------------------------------------------------------------

  /// Referensi instance [FirebaseFirestore] yang di-inject ke repositori ini.
  FirebaseFirestore get firestoreInstance => _firestore;

  /// Referensi koleksi `stock_logs` untuk audit mutasi stok oleh Anggota 3.
  CollectionReference<Map<String, dynamic>> get stockLogsCollection =>
      _firestore.collection(AppConstants.collectionStockLogs);

  // ================= AREA KERJA ORANG 3 (CRUD STOK & LOW STOCK) =================
  // Ruang implementasi Anggota 3: CRUD master menu, penyesuaian stok, dan low stock.
  // Tulis seluruh method mutasi (addMenu, updateMenu, updateQuickStock, deleteMenu) di area ini.
}
