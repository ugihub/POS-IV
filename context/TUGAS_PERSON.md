# Pembagian Tugas Tim & Spesifikasi Jurnal Praktikum (TUGAS_PERSON.md)

**Nama Proyek:** Aplikasi Mobile POS, Kitchen Display System (KDS), dan Monitoring Rantai Pasok Internal Berbasis QR Table  
**Jumlah Anggota Tim:** $3\text{ Orang}$  
**Acuan Dokumen:** `PRD.md`, `ARCHITECTURE.md`, `schema.sql`, `API_SPEC.md`, `GEMINI.md`, `PLAN.md`, dan `DESIGN.md`  

---

## 1. Matriks Pembagian Peran & Cakupan Tugas Praktikum

Pembagian kerja dirancang berdasarkan tahapan **Rantai Pasok Internal (*Internal Supply Chain*)** dan dipetakan langsung terhadap seluruh syarat tugas praktikum agar setiap anggota memiliki tanggung jawab yang seimbang dan bebas dari konflik penggabungan kode (*merge conflict*):

| Anggota | Fokus Rantai Pasok | Modul Fitur Utama | Syarat Tugas Praktikum yang Dicakup |
| :--- | :--- | :--- | :--- |
| **Anggota 1** | **Hulu (*Demand Capture*)**<br/>Pelanggan & Katalog Menu | Scan QR Meja, Katalog Real-Time, Keranjang Belanja, Lacak Status Pesanan | **Poin 2 & 4:** Fitur pencarian nama barang/menu menggunakan `RegExp` pada repositori & rumusan proyek akhir. |
| **Anggota 2** | **Tengah (*Order Fulfillment*)**<br/>Auth, Kasir (POS) & Dapur (KDS) | Multi-Role Login, Verifikasi Bayar Kasir, Antrean FIFO Dapur, Transaksi Atomik | **Poin 3 & 4:** Penyimpanan preferensi Mode Gelap (`shared_preferences`) pada `ThemeData` aplikasi & rumusan proyek akhir. |
| **Anggota 3** | **Hilir (*Inventory & Monitoring*)**<br/>Manajer & Kontrol Stok Logistik | Dashboard KPI Manajer, Peringatan *Low Stock*, CRUD Menu & Audit Mutasi Stok | **Poin 1 & 4:** Formulir penambahan/penyesuaian stok dengan validasi input (standar Modul 7) & rumusan proyek akhir. |

---

## 2. Rincian Tugas Teknis & Kepemilikan File (*File Ownership*)

Seluruh path file di bawah ini mengacu secara presisi pada struktur direktori di `ARCHITECTURE.md` dan spesifikasi komponen di `DESIGN.md`.

### 2.1 Anggota 1: Modul Pelanggan (Guest QR), Pencarian `RegExp` & Keranjang

Bertanggung jawab atas alur inisialisasi meja dari kamera QR, penyaringan katalog menu dengan ekspresi reguler, hingga pengiriman pesanan pelanggan.

* **Daftar Task pada `PLAN.md`:**
  * `Task 1.2` (Bagian `regex_patterns.dart`)
  * `Task 2.3` (`MenuModel`)
  * `Task 3.2` (`MenuRepository` — Stream Katalog & Filter `RegExp`)
  * `Task 4.2` (`MenuFilterProvider`)
  * `Task 4.3` (`CartProvider`)
  * `Task 4.4` (Bagian `MenuCardWidget` & `SearchRegExpBar`)
  * `Task 5.2` (`QrScannerScreen`)
  * `Task 5.3` (`CustomerMenuScreen` & `CartScreen`)
  * `Task 5.4` (`OrderStatusScreen`)
  * `Task 6.1` (Bagian Unit Test Filter `RegExp` & Kalkulasi Keranjang)

* **File yang Dikerjakan (`lib/`):**
  ```text
  lib/
  ├── core/constants/regex_patterns.dart          # Pola RegExp '^MEJA-\d{2}$' & helper pencarian
  ├── models/menu_model.dart                      # Model menu + getter isAvailable & isLowStock
  ├── repositories/menu_repository.dart           # Bagian: watchMenus() & filter pencarian RegExp
  ├── providers/
  │   ├── menu_filter_provider.dart               # State kata kunci pencarian RegExp & filter kategori
  │   └── cart_provider.dart                      # State nomorMeja, item keranjang, & kalkulasi totalHarga
  ├── widgets/
  │   └── menu_card_widget.dart                   # Kartu katalog menu + SearchRegExpBar
  └── screens/customer/
      ├── qr_scanner_screen.dart                  # Pemindai kamera QR meja (mobile_scanner)
      ├── customer_menu_screen.dart               # Katalog menu pelanggan real-time
      ├── cart_screen.dart                        # Ringkasan keranjang & eksekusi checkout
      └── order_status_screen.dart                # Pantau status pesanan pelanggan (4 tahap)
  ```

* **Pemetaan Endpoint & Logika Utama:**
  * Validasi string QR meja wajib memenuhi pola `^MEJA-\d{2}$` (`POST /api/v1/auth/validate-qr`).
  * Pencarian nama menu wajib menggunakan `RegExp(query, caseSensitive: false)` (`GET /api/v1/menus?search=...`).
  * Kuantitas tiap item di keranjang wajib divalidasi memenuhi $1 \le \text{qty} \le \text{stok}$ dan menghitung $\text{totalHarga} = \sum_{i=1}^{n} (\text{harga}_i \times \text{qty}_i)$.

---

### 2.2 Anggota 2: Modul Autentikasi, Kasir (POS), Kitchen (KDS) & Dark Mode

Bertanggung jawab atas fondasi tema aplikasi (*Dark/Light Mode*), sistem autentikasi *multi-role*, transaksi pemotongan/pengembalian stok secara atomik, serta antarmuka Kasir dan Dapur.

* **Daftar Task pada `PLAN.md`:**
  * `Task 1.1` (Setup `pubspec.yaml` & izin kamera Android/iOS)
  * `Task 1.4` (`AppTheme`, `ThemeRepository`, `ThemeProvider` — Mode Gelap)
  * `Task 2.1` (Bagian `firestore.indexes.json` untuk antrean FIFO)
  * `Task 2.2` (`UserModel`)
  * `Task 2.4` (`OrderItemModel` & `OrderModel`)
  * `Task 3.1` (`AuthRepository`)
  * `Task 3.4` (`OrderRepository` — Transaksi Stok Atomik `runTransaction`)
  * `Task 3.5` (`OrderRepository` — Verifikasi Kasir, Antrean FIFO Dapur & Rollback Batal)
  * `Task 4.1` (`AuthProvider`)
  * `Task 4.4` (Bagian `ThemeToggleButton`, `OrderTicketCard`, & `StatusBadge`)
  * `Task 5.1` (`main.dart`, `LandingScreen`, & `LoginScreen`)
  * `Task 5.5` (`KasirDashboard` & `WalkinPosScreen`)
  * `Task 5.6` (`KdsQueueScreen` & `QuickStockScreen`)
  * `Task 6.2` (Pengujian *Race Condition* Stok Habis)

* **File yang Dikerjakan (`lib/`):**
  ```text
  lib/
  ├── main.dart                                   # Inisialisasi Firebase, MultiProvider, & ThemeData
  ├── core/theme/app_theme.dart                   # Konfigurasi ThemeData Light & Dark Mode (Material 3)
  ├── models/
  │   ├── user_model.dart                         # Model akun staf ('kasir', 'kitchen', 'manager')
  │   ├── order_item_model.dart                   # Model snapshot item pesanan (nama & harga historis)
  │   └── order_model.dart                        # Model dokumen transaksi pesanan
  ├── repositories/
  │   ├── theme_repository.dart                   # Persistensi 'pref_dark_mode' di SharedPreferences
  │   ├── auth_repository.dart                    # Login Firebase Auth & pengecekan role
  │   └── order_repository.dart                   # Bagian: runTransaction() order, FIFO stream, & status update
  ├── providers/
  │   ├── theme_provider.dart                     # State aktif ThemeMode (Light/Dark)
  │   └── auth_provider.dart                      # State sesi staf & role routing guard
  ├── widgets/
  │   ├── theme_toggle_button.dart                # Tombol switch mode gelap/terang di AppBar
  │   └── order_ticket_card.dart                  # Kartu tiket pesanan Kasir & Kitchen + StatusBadge
  └── screens/
      ├── auth/
      │   ├── landing_screen.dart                 # Layar awal: pilih Scan QR Pelanggan atau Login Staf
      │   └── login_screen.dart                   # Halaman login staf operasional
      ├── kasir/
      │   ├── kasir_dashboard.dart                # Verifikasi 'pending_payment' & batalkan pesanan
      │   └── walkin_pos_screen.dart              # Input pesanan manual ('WALK-IN') oleh kasir
      └── kitchen/
          ├── kds_queue_screen.dart               # Layar antrean produksi FIFO ('in_kitchen' & 'ready')
          └── quick_stock_screen.dart             # Kontrol cepat ubah/nolkan stok menu dari dapur
  ```

* **Pemetaan Endpoint & Logika Utama:**
  * Penyimpanan preferensi Mode Gelap ke `SharedPreferences` dengan key `'pref_dark_mode'` dan penerapan pada `MaterialApp.themeMode`.
  * Eksekusi `FirebaseFirestore.instance.runTransaction()` saat membuat pesanan (`POST /api/v1/orders`) dan membatalkan pesanan (`PATCH /api/v1/orders/:order_id/cancel`).
  * Transisi status searah: `pending_payment` $\rightarrow$ `in_kitchen` $\rightarrow$ `ready` $\rightarrow$ `completed` dengan urutan antrean dapur FIFO (`waktuPesan ASC`).

---

### 2.3 Anggota 3: Modul Manajer, Formulir Validasi Stok & Analitik Rantai Pasok

Bertanggung jawab atas utilitas validasi input (menggantikan tombol data contoh sesuai tugas praktikum poin 1), CRUD inventaris menu, pencatatan riwayat mutasi stok (`stock_logs`), dan *dashboard* analitik manajer.

* **Daftar Task pada `PLAN.md`:**
  * `Task 1.2` (Bagian `app_constants.dart`)
  * `Task 1.3` (`currency_formatter.dart` & `validators.dart`)
  * `Task 2.1` (Bagian `schema.sql` & *seed data* awal koleksi `users` dan `menus`)
  * `Task 3.3` (`MenuRepository` — CRUD Menu & Mutasi Stok `stock_logs`)
  * `Task 3.6` (`OrderRepository` — Agregasi KPI Harian & Riwayat Log Stok)
  * `Task 4.4` (Bagian `EmptyStateWidget`)
  * `Task 5.7` (`ManagerDashboard` — KPI & Peringatan *Low Stock*)
  * `Task 5.8` (`MenuFormScreen` — Formulir Validasi Penambahan/Edit Stok)
  * `Task 5.9` (`OrderHistoryScreen` — Riwayat Transaksi & Pencarian `RegExp`)
  * `Task 6.1` (Bagian Unit Test Validator Form)
  * `Task 6.3` (Finalisasi Linter & Build APK)

* **File yang Dikerjakan (`lib/`):**
  ```text
  lib/
  ├── core/
  │   ├── constants/app_constants.dart            # Konstanta nama koleksi, status pesanan, & role
  │   └── utils/
  │       ├── currency_formatter.dart             # Format nominal Rupiah (intl)
  │       └── validators.dart                     # Fungsi validasi Form sesuai standar Modul 7
  ├── repositories/
  │   ├── menu_repository.dart                    # Bagian: addMenu(), updateMenu(), updateQuickStock(), deleteMenu()
  │   └── order_repository.dart                   # Bagian: watchDailyAnalytics() & watchStockLogs()
  ├── widgets/
  │   └── empty_state_widget.dart                 # Komponen tampilan saat daftar/pencarian kosong
  └── screens/manager/
      ├── manager_dashboard.dart                  # Kartu KPI harian & daftar peringatan Low Stock
      ├── menu_form_screen.dart                   # Formulir tambah/edit menu & stok dengan validasi penuh
      └── order_history_screen.dart               # Riwayat pesanan (filter RegExp meja) & audit stock_logs
  ```

* **Pemetaan Endpoint & Logika Utama:**
  * Validasi formulir penambahan/penyesuaian stok (`POST /api/v1/menus` & `PUT /api/v1/menus/:menu_id`):
    * Nama menu wajib diisi ($\text{panjang karakter} \ge 3$).
    * Harga wajib angka positif ($> 0$).
    * Stok dan batas minimum wajib bilangan bulat non-negatif ($\ge 0$).
  * Deteksi indikator peringatan stok menipis menggunakan rumus $\text{isLowStock} = (\text{stok} \le \text{batasMinimum})$ (`GET /api/v1/analytics/dashboard`).

---

## 3. Alur Kerja Kolaborasi & Strategi Branch Git

Untuk memastikan pengerjaan paralel berjalan mulus tanpa saling menimpa kode, ikuti urutan integrasi berikut:

1. **Tahap Fondasi Bersama (Hari 1):**
   * Selesaikan **Fase 1** dan **Fase 2** (`app_constants.dart`, `regex_patterns.dart`, `validators.dart`, `app_theme.dart`, serta ke-4 kelas di `lib/models/`) terlebih dahulu dan gabungkan ke branch `main`.
2. **Pembagian Branch Fitur (Hari 2–5):**
   * **Anggota 1:** Bekerja pada branch `feat/member1-customer-qr`
   * **Anggota 2:** Bekerja pada branch `feat/member2-pos-kds-theme`
   * **Anggota 3:** Bekerja pada branch `feat/member3-manager-stock`
3. **Aturan File Bersama (`menu_repository.dart` & `order_repository.dart`):**
   * Pada `menu_repository.dart`: Anggota 1 menulis fungsi pembacaan *stream* dan filter `RegExp`, sedangkan Anggota 3 menulis fungsi mutasi CRUD (`addMenu`, `updateMenu`, `updateQuickStock`, `deleteMenu`).
   * Pada `order_repository.dart`: Anggota 2 menulis fungsi transaksi pesanan dan antrean FIFO dapur, sedangkan Anggota 3 menulis fungsi agregasi KPI manajer dan pembacaan `stock_logs`.
4. **Verifikasi Sebelum Pull Request:**
   * Setiap anggota wajib menjalankan `dart format lib/` dan `flutter analyze` (pastikan $0\text{ error}$) sebelum melakukan *merge* ke `main`.

---

## 4. Narasi Siap Salin untuk Jurnal Praktikum (Tugas Poin 4 — Persiapan Modul 12)

Sesuai instruksi pada lembar tugas praktikum, **Bagian A s.d. D ditulis seragam oleh seluruh anggota kelompok**, sedangkan **Bagian E ditulis berbeda pada jurnal masing-masing praktikan** sesuai porsi yang dikerjakan sendiri:

### Bagian Seragam (Ditulis Sama oleh Anggota 1, 2, dan 3)

* **A. Judul Proyek:**  
  Rancang Bangun Aplikasi *Mobile* POS dan Sistem Distribusi Pesanan (*Kitchen Display System*) Berbasis Flutter dengan Dukungan *QR Table* untuk Efisiensi Rantai Pasok Internal Kafe/Restoran.
* **B. Permasalahan:**  
  Sering terjadi hambatan komunikasi dan keterlambatan distribusi pesanan antara kasir dan bagian dapur (*kitchen*), kesalahan pencatatan nomor meja, serta ketidaksinkronan informasi stok menu yang habis antara bagian depan dan dapur, sehingga manajer sulit memantau kelancaran operasional dan ketersediaan stok logistik secara *real-time*.
* **C. Pengguna Sasaran:**  
  Pelanggan (pemindai QR meja), Staf Kasir, Staf Dapur (*Kitchen*), dan Manajer Restoran/Kafe skala kecil hingga menengah.
* **D. Tiga Fitur Utama:**  
  1. **Pemesanan Mandiri Berbasis QR Meja (*QR Table Ordering*):** Pemindaian kode QR meja untuk deteksi nomor meja otomatis, pencarian katalog menu yang stoknya tersedia menggunakan ekspresi reguler (`RegExp`), dan pengiriman pesanan.
  2. **Sinkronisasi Alur Pesanan Kasir & Dapur (*Real-Time Order Fulfillment*):** Verifikasi transaksi oleh kasir yang terhubung langsung dengan layar antrean produksi dapur (*Kitchen Display System*) berurutan FIFO secara *real-time* beserta pemotongan stok otomatis.
  3. **Manajemen Inventaris & Dashboard Pemantauan Manajer:** Pengelolaan penambahan stok menu dengan validasi formulir, peringatan stok minimum (*low stock alert*), dan pemantauan kinerja pemenuhan pesanan harian dengan dukungan tema Mode Gelap (*Dark Mode*).

---

### Bagian Individu: E. Keterangan Bagian yang Dikerjakan Sendiri

#### Pilihan 1 — Untuk Jurnal Anggota 1:
> "Pada proyek akhir ini, saya bertanggung jawab mengerjakan modul hulu pemesanan pelanggan (*Customer QR Table Ordering*) dan fitur pencarian katalog menu. Bagian spesifik yang saya kerjakan sendiri meliputi: (1) perancangan `MenuModel` serta implementasi fitur pencarian nama barang/menu menggunakan ekspresi reguler (`RegExp`) pada `MenuRepository` dan `MenuFilterProvider`, (2) integrasi kamera pemindai kode QR meja (`QrScannerScreen` menggunakan `mobile_scanner`) beserta validasi pola nomor meja, serta (3) pembuatan antarmuka katalog menu pelanggan (`CustomerMenuScreen`), pengelolaan state keranjang belanja (`CartScreen` & `CartProvider`), dan layar pelacakan status pesanan secara *real-time* (`OrderStatusScreen`)."

#### Pilihan 2 — Untuk Jurnal Anggota 2:
> "Pada proyek akhir ini, saya bertanggung jawab mengerjakan modul autentikasi *multi-role*, operasional transaksi Kasir (POS), antrean produksi dapur (*Kitchen Display System*), serta konfigurasi Mode Gelap aplikasi. Bagian spesifik yang saya kerjakan sendiri meliputi: (1) implementasi penyimpanan preferensi Mode Gelap (*Dark Mode*) menggunakan `shared_preferences` pada `ThemeRepository` dan `ThemeProvider` yang diterapkan langsung ke `ThemeData` aplikasi, (2) perancangan `OrderModel` dan logika transaksi database atomik (`runTransaction`) pada `OrderRepository` untuk memotong serta mengembalikan stok secara *real-time*, serta (3) pembuatan antarmuka verifikasi pembayaran kasir (`KasirDashboard` & `WalkinPosScreen`) dan layar antrean dapur berurutan FIFO (`KdsQueueScreen` & `QuickStockScreen`)."

#### Pilihan 3 — Untuk Jurnal Anggota 3:
> "Pada proyek akhir ini, saya bertanggung jawab mengerjakan modul pengendalian inventaris logistik, validasi formulir stok, dan *Dashboard Monitoring* Manajer. Bagian spesifik yang saya kerjakan sendiri meliputi: (1) pembuatan formulir penambahan dan penyesuaian stok menu (`MenuFormScreen`) dengan validasi input lengkap pada `validators.dart` (menggantikan tombol data contoh sesuai standar Modul 7), (2) implementasi fungsi CRUD inventaris menu, pencatatan riwayat mutasi stok (`stock_logs`), serta logika deteksi peringatan stok menipis (*low stock alert* saat $\text{stok} \le \text{batasMinimum}$), serta (3) pembuatan halaman `ManagerDashboard` untuk memantau KPI pendapatan harian dan `OrderHistoryScreen` yang dilengkapi pencarian riwayat transaksi berbasis `RegExp`."