/// Konstanta global untuk seluruh modul aplikasi POS, KDS, dan Monitoring Stok.
class AppConstants {
  AppConstants._();

  // Nama koleksi Cloud Firestore
  static const String collectionUsers = 'users';
  static const String collectionMenus = 'menus';
  static const String collectionOrders = 'orders';
  static const String collectionStockLogs = 'stock_logs';

  // Peran (role) staf internal
  static const String roleKasir = 'kasir';
  static const String roleKitchen = 'kitchen';
  static const String roleManager = 'manager';
  static const List<String> validRoles = <String>[
    roleKasir,
    roleKitchen,
    roleManager,
  ];

  // Status siklus hidup pesanan (State Machine)
  static const String statusPendingPayment = 'pending_payment';
  static const String statusInKitchen = 'in_kitchen';
  static const String statusReady = 'ready';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const List<String> validOrderStatuses = <String>[
    statusPendingPayment,
    statusInKitchen,
    statusReady,
    statusCompleted,
    statusCancelled,
  ];

  // Kategori menu standar
  static const String categoryMakanan = 'makanan';
  static const String categoryMinuman = 'minuman';
  static const String categorySnack = 'snack';
  static const List<String> validCategories = <String>[
    categoryMakanan,
    categoryMinuman,
    categorySnack,
  ];

  // Kunci penyimpanan lokal SharedPreferences
  static const String prefDarkModeKey = 'is_dark_mode';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String prefDarkMode = 'pref_dark_mode';

  // Pola RegExp & konstanta identitas meja QR
  static const String tableNumberPattern = r'^MEJA-\d{2}$';
  static const String tableNumberRegex = r'^MEJA-\d{2}$';
  static const String walkInTable = 'WALK-IN';
  static const int defaultMinStock = 5;
}
