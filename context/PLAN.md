# Implementation Plan & Coding Roadmap (PLAN.md)

**Nama Proyek:** Aplikasi Mobile POS, Kitchen Display System (KDS), dan Monitoring Rantai Pasok Internal Berbasis QR Table  
**Platform & Tech Stack:** Flutter ($\ge 3.19.x$), Dart ($\ge 3.0.0$), Firebase (`firebase_auth`, `cloud_firestore`), `provider`, `mobile_scanner`, `shared_preferences`, `intl`  
**Acuan Spesifikasi:** `PRD.md`, `ARCHITECTURE.md`, `schema.sql`, `API_SPEC.md`, dan `GEMINI.md`

---

## Fase 1: Setup Proyek, Konfigurasi Lingkungan & Utilitas Inti (`Core & Setup`)

Fase ini berfokus pada persiapan dependensi proyek, perizinan perangkat keras kamera, konstanta sistem, fungsi validasi input, serta fondasi penyimpanan preferensi Mode Gelap (*Dark Mode*).

- [ ] **Task 1.1: Inisialisasi Dependensi & Konfigurasi Izin Kamera**
  - **File:** `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`
  - **Detail Implementasi:** Tambahkan paket `firebase_core`, `firebase_auth`, `cloud_firestore`, `provider`, `mobile_scanner`, `shared_preferences`, dan `intl`. Tambahkan deklarasi `<uses-permission android:name="android.permission.CAMERA" />` pada Android dan `NSCameraUsageDescription` pada iOS.
  - **Kriteria Uji:** Perintah `flutter pub get` berjalan sukses tanpa konflik versi.

- [ ] **Task 1.2: Konfigurasi Firebase CLI & Konstanta Global**
  - **File:** `lib/firebase_options.dart`, `lib/core/constants/app_constants.dart`, `lib/core/constants/regex_patterns.dart`
  - **Detail Implementasi:** Hubungkan proyek dengan Firebase melalui FlutterFire CLI. Buat konstanta nama koleksi (`users`, `menus`, `orders`, `stock_logs`), daftar *role* (`kasir`, `kitchen`, `manager`), status pesanan (`pending_payment`, `in_kitchen`, `ready`, `completed`, `cancelled`), kunci `SharedPreferences` (`pref_dark_mode`), dan pola RegExp validasi QR meja (`^MEJA-\d{2}$`).
  - **Kriteria Uji:** `flutter analyze` menghasilkan $0$ *error* pada direktori `lib/core/constants/`.

- [ ] **Task 1.3: Pembuatan Helper Pemformatan Rupiah & Validator Formulir**
  - **File:** `lib/core/utils/currency_formatter.dart`, `lib/core/utils/validators.dart`
  - **Detail Implementasi:** Implementasikan fungsi format angka ke Rupiah (`Rp`) menggunakan paket `intl`. Buat fungsi validator formulir sesuai aturan bisnis: nama menu wajib diisi ($\ge 3$ karakter), harga wajib angka positif ($> 0$), serta stok dan batas minimum wajib bilangan bulat non-negatif ($\ge 0$).
  - **Kriteria Uji:** Panggil fungsi validator dengan input tidak valid (misal harga $-500$ atau nama `"ab"`) dan pastikan mengembalikan pesan *error* yang tepat.

- [ ] **Task 1.4: Implementasi Repositori, Provider & Konfigurasi Tema (`Dark/Light Mode`)**
  - **File:** `lib/core/theme/app_theme.dart`, `lib/repositories/theme_repository.dart`, `lib/providers/theme_provider.dart`
  - **Detail Implementasi:** Definisikan `ThemeData` untuk mode terang dan gelap (Material 3). Buat `ThemeRepository` untuk membaca dan menyimpan boolean `pref_dark_mode` di `SharedPreferences`, lalu hubungkan ke `ThemeProvider` (`ChangeNotifier`).
  - **Kriteria Uji:** Saat nilai tema diubah melalui `ThemeProvider.toggleTheme()`, status tersimpan di penyimpanan lokal dan tetap bertahan saat aplikasi dijalankan ulang.

---

## Fase 2: Skema Database, Index Firestore & Model Data (`Database & Models`)

Fase ini menerjemahkan skema relasional pada `schema.sql` dan struktur dokumen pada `PRD.md` menjadi pengaturan Cloud Firestore serta kelas model Dart yang *immutable* dan *type-safe*.

- [ ] **Task 2.1: Konfigurasi Koleksi, Aturan Keamanan & Composite Index Firestore**
  - **File:** `schema.sql`, `firestore.indexes.json`, `firestore.rules`
  - **Detail Implementasi:** Buat indeks komposit wajib pada koleksi `orders` dengan field `status` (*Ascending*) dan `waktuPesan` (*Ascending*) untuk mendukung antrean FIFO dapur. Siapkan *seed data* awal di Firestore untuk $3$ akun staf (`kasir`, `kitchen`, `manager`) pada koleksi `users`.
  - **Kriteria Uji:** Kueri gabungan `.where('status', whereIn: ['in_kitchen', 'ready']).orderBy('waktuPesan', descending: false)` dapat dieksekusi tanpa melempar `FirebaseException: failed-precondition`.

- [ ] **Task 2.2: Implementasi `UserModel`**
  - **File:** `lib/models/user_model.dart`
  - **Detail Implementasi:** Buat kelas *immutable* `UserModel` dengan properti `uid`, `nama`, `email`, `role`, dan `createdAt`, lengkap dengan *factory* `fromMap()`, method `toMap()`, dan `copyWith()`.
  - **Kriteria Uji:** Serialisasi dan deserialisasi objek `UserModel` dari `Map<String, dynamic>` berjalan akurat tanpa kehilangan tipe data.

- [ ] **Task 2.3: Implementasi `MenuModel` beserta Kalkulasi Indikator Stok**
  - **File:** `lib/models/menu_model.dart`
  - **Detail Implementasi:** Buat kelas `MenuModel` (`menuId`, `nama`, `kategori`, `harga`, `stok`, `batasMinimum`, `isActive`, `updatedAt`). Tambahkan *getter* kalkulasi logistik: `bool get isAvailable => stok > 0` dan `bool get isLowStock => stok <= batasMinimum`.
  - **Kriteria Uji:** Objek `MenuModel` dengan $\text{stok} = 3$ dan $\text{batasMinimum} = 5$ menghasilkan `isLowStock == true` dan `isAvailable == true`.

- [ ] **Task 2.4: Implementasi `OrderItemModel` & `OrderModel`**
  - **File:** `lib/models/order_item_model.dart`, `lib/models/order_model.dart`
  - **Detail Implementasi:** Buat `OrderItemModel` yang menyimpan *snapshot* transaksi (`menuId`, `namaMenuSnapshot`, `hargaSatuanSnapshot`, `qty`, serta *getter* $\text{subtotal} = \text{hargaSatuanSnapshot} \times \text{qty}$). Buat `OrderModel` (`orderId`, `nomorMeja`, `items`, `totalHarga`, `status`, `verifiedByUid`, `waktuPesan`, `waktuSelesai`) dengan konversi `Timestamp` Firestore ke `DateTime`.
  - **Kriteria Uji:** `OrderModel.fromMap()` mampu mem-parsing *array of map* `items` menjadi `List<OrderItemModel>` dan menghitung total harga dengan tepat.

---

## Fase 3: Lapisan Repositori, Logika Bisnis & Pemetaan Endpoint (`Core Backend / Repository Layer`)

Fase ini mengimplementasikan seluruh aturan bisnis, pencarian `RegExp`, dan transaksi atomik sesuai spesifikasi pada `API_SPEC.md`.

- [ ] **Task 3.1: Implementasi `AuthRepository` (Login Staf, Profil & Validasi QR Meja)**
  - **File:** `lib/repositories/auth_repository.dart`
  - **Pemetaan Endpoint:** `POST /api/v1/auth/login`, `GET /api/v1/auth/me`, `POST /api/v1/auth/validate-qr`
  - **Detail Implementasi:** Buat fungsi `signInWithEmailPassword()` yang mengautentikasi via `FirebaseAuth` lalu mengambil dokumen peran pengguna dari koleksi `users`. Buat fungsi `validateQrTable(String qrString)` yang memvalidasi string terhadap pola RegExp `^MEJA-\d{2}$`.
  - **Kriteria Uji:** Login dengan kredensial valid mengembalikan `UserModel` sesuai perannya; input QR `"MEJA-05"` lolos validasi sedangkan `"HTTP://LINK"` ditolak dengan pesan *error* yang jelas.

- [ ] **Task 3.2: Implementasi `MenuRepository` — Stream Katalog & Filter `RegExp`**
  - **File:** `lib/repositories/menu_repository.dart`
  - **Pemetaan Endpoint:** `GET /api/v1/menus`
  - **Detail Implementasi:** Buat fungsi `watchMenus()` yang mengembalikan `Stream<List<MenuModel>>`. Implementasikan fungsi penyaringan pencarian nama barang menggunakan `RegExp(query, caseSensitive: false)` serta filter `kategori` dan `lowStockOnly`.
  - **Kriteria Uji:** Pencarian dengan kata kunci `"gor"` menggunakan `RegExp` berhasil mencocokkan `"Nasi Goreng Spesial"` dan `"Kentang Goreng Crispy"` secara *case-insensitive*.

- [ ] **Task 3.3: Implementasi `MenuRepository` — CRUD Menu & Penyesuaian Stok Cepat**
  - **File:** `lib/repositories/menu_repository.dart`
  - **Pemetaan Endpoint:** `POST /api/v1/menus`, `PUT /api/v1/menus/:menu_id`, `PATCH /api/v1/menus/:menu_id/stock`, `DELETE /api/v1/menus/:menu_id`
  - **Detail Implementasi:** Buat fungsi `addMenu()`, `updateMenu()`, `updateQuickStock()` (mengubah `menus.stok` sekaligus mencatat riwayat ke koleksi `stock_logs`), dan `deleteMenu()` (memeriksa keterkaitan transaksi sebelum menghapus).
  - **Kriteria Uji:** Pemanggilan `updateQuickStock()` berhasil memperbarui angka stok di koleksi `menus` dan menambah dokumen audit baru di `stock_logs`.

- [ ] **Task 3.4: Implementasi `OrderRepository` — Checkout Pesanan dengan Transaksi Stok Atomik**
  - **File:** `lib/repositories/order_repository.dart`
  - **Pemetaan Endpoint:** `POST /api/v1/orders`
  - **Detail Implementasi:** Buat fungsi `createOrderWithStockTransaction()` menggunakan `FirebaseFirestore.instance.runTransaction()`. Di dalam transaksi: baca seluruh dokumen `menus` yang dipesan, pastikan $\text{stok} \ge \text{qty}$ untuk setiap item, kurangi `menus.stok` sebesar `qty`, buat dokumen `orders` baru, dan catat mutasi di `stock_logs`.
  - **Kriteria Uji:** Jika jumlah pesanan melebihi sisa stok di database, transaksi gagal sepenuhnya (*rollback*) dan melempar *exception* `INSUFFICIENT_STOCK` tanpa mengubah stok item lain.

- [ ] **Task 3.5: Implementasi `OrderRepository` — Transisi Status, Antrean FIFO & Rollback Pembatalan**
  - **File:** `lib/repositories/order_repository.dart`
  - **Pemetaan Endpoint:** `GET /api/v1/orders`, `GET /api/v1/orders/:order_id`, `PATCH /api/v1/orders/:order_id/verify-payment`, `PATCH /api/v1/orders/:order_id/cancel`, `PATCH /api/v1/orders/:order_id/kitchen-status`
  - **Detail Implementasi:**
    1. Buat `watchKitchenQueueFifo()` dengan pengurutan `waktuPesan` *ascending*.
    2. Buat `verifyPayment()` untuk mengubah status `pending_payment` $\rightarrow$ `in_kitchen`.
    3. Buat `updateKitchenStatus()` untuk transisi `in_kitchen` $\rightarrow$ `ready` $\rightarrow$ `completed`.
    4. Buat `cancelOrderWithStockRollback()` menggunakan `runTransaction()` untuk mengubah status `pending_payment` $\rightarrow$ `cancelled` dan mengembalikan (`increment`) `menus.stok` sejumlah `qty` item pesanan.
  - **Kriteria Uji:** Membatalkan pesanan berstatus `pending_payment` otomatis mengembalikan jumlah stok menu terkait ke angka semula.

- [ ] **Task 3.6: Implementasi `OrderRepository` — Analitik KPI Manajer & Riwayat Log Stok**
  - **File:** `lib/repositories/order_repository.dart`
  - **Pemetaan Endpoint:** `GET /api/v1/analytics/dashboard`, `GET /api/v1/stock-logs`
  - **Detail Implementasi:** Buat stream dan fungsi agregasi untuk menghitung total pendapatan harian dari pesanan berstatus `completed`, jumlah antrean aktif di dapur (`in_kitchen`), jumlah pesanan menunggu bayar (`pending_payment`), serta stream riwayat `stock_logs`.
  - **Kriteria Uji:** Saat pesanan diubah menjadi `completed`, metrik total pendapatan harian langsung bertambah sesuai `totalHarga` pesanan tersebut.

---

## Fase 4: Manajemen State & Komponen UI Bersama (`Providers & Shared Widgets`)

Fase ini menghubungkan lapisan repositori ke *state management* `provider` dan membangun komponen antarmuka yang digunakan bersama di berbagai layar.

- [ ] **Task 4.1: Implementasi `AuthProvider` & Guard Hak Akses Role**
  - **File:** `lib/providers/auth_provider.dart`
  - **Detail Implementasi:** Kelola *state* pengguna aktif (`UserModel?`), indikator *loading*, pesan *error* autentikasi, fungsi `login()`, `logout()`, dan pengecekan izin peran (`isKasir`, `isKitchen`, `isManager`).
  - **Kriteria Uji:** Perubahan status autentikasi memicu `notifyListeners()` dan mengarahkan pengguna ke halaman sesuai `role`.

- [ ] **Task 4.2: Implementasi `MenuFilterProvider` (State Pencarian `RegExp` & Kategori)**
  - **File:** `lib/providers/menu_filter_provider.dart`
  - **Detail Implementasi:** Kelola *state* string kueri pencarian nama menu, kueri pencarian nomor meja, dan filter kategori terpilih. Terapkan fungsi filter berbasis `RegExp` pada daftar menu/pesanan yang masuk dari stream.
  - **Kriteria Uji:** Mengubah kueri pencarian langsung menyaring daftar item secara reaktif tanpa memanggil ulang jaringan apabila data stream sudah tersedia.

- [ ] **Task 4.3: Implementasi `CartProvider` (Sesi Meja QR & Kalkulasi Keranjang)**
  - **File:** `lib/providers/cart_provider.dart`
  - **Detail Implementasi:** Kelola *state* `nomorMeja` aktif, daftar item di keranjang (`Map<String, OrderItemModel>`), validasi penambahan kuantitas agar memenuhi $1 \le \text{qty} \le \text{stok}$, kalkulasi $\text{totalHarga} = \sum (\text{harga}_i \times \text{qty}_i)$, dan fungsi `submitOrder()` yang memanggil `OrderRepository.createOrderWithStockTransaction()`.
  - **Kriteria Uji:** Menambah item melebihi `menus.stok` ditolak oleh `CartProvider`, dan pemanggilan `submitOrder()` mengosongkan keranjang setelah transaksi sukses.

- [ ] **Task 4.4: Pembuatan Komponen Widget Bersama (`Reusable Widgets`)**
  - **File:** `lib/widgets/theme_toggle_button.dart`, `lib/widgets/empty_state_widget.dart`, `lib/widgets/menu_card_widget.dart`, `lib/widgets/order_ticket_card.dart`
  - **Detail Implementasi:**
    1. `ThemeToggleButton`: Ikon *switch* mode gelap/terang untuk `AppBar`.
    2. `EmptyStateWidget`: Tampilan informatif saat daftar kosong atau hasil pencarian `RegExp` tidak ditemukan.
    3. `MenuCardWidget`: Kartu informasi menu dengan *badge* sisa stok, indikator warna merah/kuning saat `isLowStock`, dan penguncian tombol pesan saat $\text{stok} = 0$.
    4. `OrderTicketCard`: Kartu tiket pesanan yang menampilkan nomor meja, rincian item, waktu pesan, dan tombol aksi kontekstual sesuai peran (`Kasir` atau `Kitchen`).
  - **Kriteria Uji:** `MenuCardWidget` otomatis menonaktifkan tombol tambah ketika $\text{stok} = 0$ dan menampilkan label *"Stok Habis"*.

---

## Fase 5: Antarmuka Pengguna & Integrasi Fitur per Peran (`Frontend Screens & Integration`)

Fase ini membangun layar fungsional untuk keempat aktor pengguna (Pelanggan QR, Kasir, Dapur, dan Manajer) beserta navigasinya.

- [ ] **Task 5.1: Integrasi `main.dart`, `LandingScreen` & `LoginScreen`**
  - **File:** `lib/main.dart`, `lib/screens/auth/landing_screen.dart`, `lib/screens/auth/login_screen.dart`
  - **Detail Implementasi:** Inisialisasi Firebase dan `MultiProvider` di `main.dart` serta hubungkan `ThemeProvider` ke `MaterialApp`. Buat `LandingScreen` dengan dua opsi utama: **"Pesan via QR Meja (Pelanggan)"** dan **"Login Staf"**. Buat `LoginScreen` dengan validasi form email/password dan *redirect* otomatis berdasarkan `role`.
  - **Kriteria Uji:** Pengguna dapat beralih mode gelap/terang dari `LandingScreen` dan staf dapat masuk ke *dashboard* masing-masing sesuai peran akunnya.

- [ ] **Task 5.2: Modul Pelanggan — Layar Pemindai QR Meja (`QrScannerScreen`)**
  - **File:** `lib/screens/customer/qr_scanner_screen.dart`
  - **Detail Implementasi:** Integrasikan widget `MobileScanner` untuk membaca QR Code meja. Tangani skenario izin kamera ditolak dengan tampilan *fallback* dan tombol pengaturan izin. Validasi hasil pindaian dengan RegExp `^MEJA-\d{2}$`; jika valid, simpan nomor meja ke `CartProvider` dan arahkan ke `CustomerMenuScreen`.
  - **Kriteria Uji:** Memindai QR bertuliskan `"MEJA-04"` membuka katalog menu dengan header `"Meja: MEJA-04"`, sedangkan QR tidak valid memunculkan peringatan `SnackBar` tanpa membuat aplikasi *crash*.

- [ ] **Task 5.3: Modul Pelanggan — Katalog Menu, Pencarian `RegExp` & Layar Keranjang (`CustomerMenuScreen` & `CartScreen`)**
  - **File:** `lib/screens/customer/customer_menu_screen.dart`, `lib/screens/customer/cart_screen.dart`
  - **Detail Implementasi:** Tampilkan katalog menu *real-time* menggunakan `StreamBuilder<List<MenuModel>>`, bilah pencarian `RegExp`, dan *chip* kategori. Buat `CartScreen` untuk meninjau daftar item, mengubah kuantitas, dan mengeksekusi tombol **"Kirim Pesanan"** beserta penanganan *error* jika terjadi *race condition* stok habis.
  - **Kriteria Uji:** Pesanan yang dikirim dari `CartScreen` berhasil tersimpan di Firestore dengan status `pending_payment` dan stok menu langsung berkurang secara *real-time*.

- [ ] **Task 5.4: Modul Pelanggan — Layar Pantau Status Pesanan Real-Time (`OrderStatusScreen`)**
  - **File:** `lib/screens/customer/order_status_screen.dart`
  - **Detail Implementasi:** Gunakan `StreamBuilder<OrderModel>` berdasarkan `orderId` aktif untuk menampilkan indikator progres pesanan pelanggan secara langsung (*Menunggu Pembayaran di Kasir* $\rightarrow$ *Sedang Dimasak di Dapur* $\rightarrow$ *Siap Diantar ke Meja* $\rightarrow$ *Selesai*).
  - **Kriteria Uji:** Saat Kasir atau Dapur mengubah status pesanan di perangkat lain, tampilan pada `OrderStatusScreen` pelanggan berubah otomatis dalam hitungan milidetik tanpa muat ulang manual.

- [ ] **Task 5.5: Modul Kasir — Dashboard Verifikasi Bayar, Pembatalan & POS Walk-in (`KasirDashboard` & `WalkinPosScreen`)**
  - **File:** `lib/screens/kasir/kasir_dashboard.dart`, `lib/screens/kasir/walkin_pos_screen.dart`
  - **Detail Implementasi:** Buat tab antrean pesanan berstatus `pending_payment` menggunakan `OrderTicketCard` dengan tombol **"Konfirmasi Bayar"** (`verifyPayment`) dan **"Batalkan Pesanan"** (`cancelOrderWithStockRollback`). Buat `WalkinPosScreen` agar kasir dapat menginput pesanan pelanggan *walk-in* (`nomorMeja: 'WALK-IN'`) yang langsung masuk ke status `in_kitchen`.
  - **Kriteria Uji:** Menekan **"Konfirmasi Bayar"** memindahkan pesanan dari layar Kasir ke layar Dapur; menekan **"Batalkan Pesanan"** mengubah status ke `cancelled` dan mengembalikan stok menu.

- [ ] **Task 5.6: Modul Kitchen — Layar Antrean KDS FIFO & Kontrol Stok Cepat (`KdsQueueScreen` & `QuickStockScreen`)**
  - **File:** `lib/screens/kitchen/kds_queue_screen.dart`, `lib/screens/kitchen/quick_stock_screen.dart`
  - **Detail Implementasi:** Tampilkan antrean pesanan berstatus `in_kitchen` dan `ready` secara FIFO (`waktuPesan` terlama di atas) dengan tombol aksi **"Siap Diantar"** (`ready`) dan **"Selesai"** (`completed`). Buat tab `QuickStockScreen` agar staf dapur dapat langsung mengurangi atau menolkan stok menu yang bahannya habis di tengah jam operasional.
  - **Kriteria Uji:** Saat staf dapur menolkan stok suatu menu pada `QuickStockScreen`, menu tersebut langsung terkunci (*Stok Habis*) pada layar pelanggan dan kasir.

- [ ] **Task 5.7: Modul Manajer — Dashboard KPI & Peringatan Stok Menipis (`ManagerDashboard`)**
  - **File:** `lib/screens/manager/manager_dashboard.dart`
  - **Detail Implementasi:** Tampilkan kartu metrik *real-time* (Total Pendapatan Harian, Pesanan Selesai, Antrean Dapur Aktif) serta daftar peringatan *Low Stock Alerts* ($\text{stok} \le \text{batasMinimum}$) dengan tombol pintas untuk *restock*.
  - **Kriteria Uji:** Setiap menu yang memiliki $\text{stok} \le \text{batasMinimum}$ otomatis muncul pada daftar peringatan di `ManagerDashboard` dengan indikator warna peringatan.

- [ ] **Task 5.8: Modul Manajer — Formulir Tambah/Edit Menu & Validasi Stok (`MenuFormScreen`)**
  - **File:** `lib/screens/manager/menu_form_screen.dart`
  - **Detail Implementasi:** Bangun formulir input menggunakan `GlobalKey<FormState>()` dan validator dari `lib/core/utils/validators.dart` untuk menambah menu baru atau memperbarui harga, stok, dan batas minimum stok (menggantikan tombol data contoh sesuai syarat tugas praktikum).
  - **Kriteria Uji:** Formulir menolak penyimpanan jika ada field kosong atau bernilai negatif, dan berhasil menyimpan dokumen ke koleksi `menus` saat seluruh validasi terpenuhi.

- [ ] **Task 5.9: Modul Manajer — Riwayat Transaksi & Pencarian `RegExp` (`OrderHistoryScreen`)**
  - **File:** `lib/screens/manager/order_history_screen.dart`
  - **Detail Implementasi:** Tampilkan daftar seluruh riwayat pesanan yang diurutkan dari waktu terbaru (`waktuPesan` *descending*), dilengkapi filter status pesanan dan kolom pencarian nomor meja/ID pesanan menggunakan `RegExp`.
  - **Kriteria Uji:** Manajer dapat menyaring riwayat transaksi untuk `"MEJA-05"` atau melihat daftar pesanan berstatus `cancelled` dan `completed` dengan akurat.

---

## Fase 6: Pengujian, Penanganan Edge Cases & Finalisasi (`Testing & Polish`)

Fase terakhir memastikan stabilitas aplikasi terhadap skenario gagal (*edge cases*), kepatuhan standar kode, dan kesiapan *build* untuk demonstrasi proyek akhir.

- [ ] **Task 6.1: Unit Testing Validator, Filter `RegExp` & Kalkulasi Keranjang**
  - **File:** `test/validators_and_filter_test.dart`
  - **Detail Implementasi:** Tulis pengujian unit (*unit test*) untuk menguji fungsi validasi form di `validators.dart`, pencocokan pola `RegExp` pencarian nama menu dan QR meja, serta perhitungan subtotal dan total harga pada `CartProvider`.
  - **Kriteria Uji:** Perintah `flutter test` berjalan sukses dengan seluruh skenario pengujian berstatus *Passed*.

- [ ] **Task 6.2: Pengujian Simulasi Edge Cases & Race Condition**
  - **File:** `lib/repositories/order_repository.dart`, `lib/screens/customer/cart_screen.dart`, `lib/screens/customer/qr_scanner_screen.dart`
  - **Detail Implementasi:** Uji dan pastikan penanganan skenario ekstrem berjalan mulus:
    1. Dua pengguna memesan sisa $1$ stok menu yang sama secara bersamaan (*race condition* ditolak oleh `runTransaction` dan memunculkan dialog peringatan).
    2. Pemindaian QR Code di luar format `^MEJA-\d{2}$`.
    3. Penanganan `ConnectionState.waiting`, `snapshot.hasError`, dan data kosong pada seluruh `StreamBuilder`.
  - **Kriteria Uji:** Tidak ada *unhandled exception* atau layar merah (*red screen of death*) saat seluruh skenario gagal disimulasikan.

- [ ] **Task 6.3: Pembersihan Linter, Formatting & Build APK Rilis**
  - **File:** Seluruh direktori `lib/` dan `pubspec.yaml`
  - **Detail Implementasi:** Pastikan seluruh `TextEditingController` dan `MobileScannerController` telah di-*dispose* dengan benar, serta setiap pemanggilan `Navigator`/`ScaffoldMessenger` setelah `await` telah memeriksa `if (!context.mounted) return;`. Jalankan pemformatan dan analisis statis sebelum mem-build APK.
  - **Kriteria Uji:** Perintah `dart format lib/` dan `flutter analyze` menghasilkan $0$ *issue*, serta `flutter build apk --release` berhasil menghasilkan file APK yang siap diinstal.