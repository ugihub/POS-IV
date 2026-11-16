# AI Coding Assistant Guidelines (GEMINI.md / CLAUDE.md / .cursorrules)

Dokumen ini adalah sumber kebenaran utama (*Single Source of Truth*) bagi AI Coding Assistant dalam menulis, memodifikasi, dan men-debug kode pada repositori ini. Patuhi seluruh instruksi di bawah ini secara ketat tanpa pengecualian.

---

## 1. Project Context Summary

Proyek ini adalah aplikasi mobile *Single-App Multi-Role* (**POS, Kitchen Display System [KDS], dan Monitoring Rantai Pasok Internal Berbasis QR Table**) yang menghubungkan Pelanggan (*Guest QR*), Kasir, Dapur (*Kitchen*), dan Manajer secara *real-time*. Sistem dibangun menggunakan **Flutter ($\ge 3.19.x$) & Dart SDK ($\ge 3.0.0$, Sound Null Safety)** dengan arsitektur serverless **Firebase** (`firebase_core`, `firebase_auth`, `cloud_firestore`), manajemen state **`provider`** (`^6.1.x`), pemindai kamera **`mobile_scanner`** (`^5.x`), persistensi lokal **`shared_preferences`** (`^2.2.x`), serta pemformatan **`intl`** (`^0.19.x`). Fokus utama logika bisnis adalah distribusi pesanan (*order fulfillment* FIFO) dan pengendalian stok inventaris secara atomik (*atomic stock deduction & rollback*).

---

## 2. Coding Conventions

* **Aturan Penamaan (*Naming Conventions*):**
  * **File & Direktori:** Wajib menggunakan `snake_case` (contoh: `order_repository.dart`, `kds_queue_screen.dart`).
  * **Class, Enum, Typedef, & Extension:** Wajib menggunakan `PascalCase` (contoh: `OrderModel`, `MenuFilterProvider`, `OrderStatus`).
  * **Variabel, Fungsi, Method, & Parameter:** Wajib menggunakan `camelCase` (contoh: `nomorMeja`, `verifyPayment()`, `isLowStock`).
  * **Konstanta:** Gunakan `camelCase` dengan keyword `const` atau `static const` di dalam kelas `AppConstants` (contoh: `static const String collectionOrders = 'orders';`).
  * **Field Database / JSON Key:** Gunakan penamaan yang presisi sesuai dokumen skema (`menuId`, `nomorMeja`, `totalHarga`, `batasMinimum`, `waktuPesan`).
* **Pengelolaan Tipe Data (*Strict Typing*):**
  * **DILARANG** menggunakan tipe `dynamic` atau `var` tanpa inferensi tipe yang jelas, kecuali saat menerima `Map<String, dynamic>` dari serialisasi Firestore/JSON.
  * Seluruh model di `lib/models/` wajib bersifat *immutable* (`final` fields) dan memiliki method `fromMap(Map<String, dynamic> map, String id)`, `toMap()`, serta `copyWith()`.
* **Gaya Penulisan Fungsi & Widget:**
  * Gunakan `const` constructor di setiap deklarasi Widget yang memungkinkan untuk optimasi *widget rebuild*.
  * Pecah method `build()` yang memiliki kedalaman lebih dari $80$ baris menjadi sub-widget terpisah (gunakan `StatelessWidget` privat, bukan *helper method* yang mengembalikan `Widget`).
  * Gunakan *named parameters* dengan keyword `required` untuk konstruktor widget atau fungsi yang memiliki lebih dari $2$ parameter.

---

## 3. Architecture & Pattern Rules

* **Layered Feature-Modular Pattern:**
  * Aliran dependensi wajib berjalan satu arah: `screens/` & `widgets/` $\rightarrow$ `providers/` $\rightarrow$ `repositories/` $\rightarrow$ `models/` & `core/`.
  * **UI Layer (`screens/`, `widgets/`):** Hanya menangani perenderan tampilan, input pengguna, dan navigasi. **DILARANG** menulis logika kalkulasi bisnis atau query Firestore langsung di dalam file UI.
  * **State Layer (`providers/`):** Mengelola *ephemeral state* (keranjang belanja, sesi nomor meja, filter pencarian `RegExp`, dan `ThemeMode`) menggunakan `ChangeNotifier`.
  * **Data Layer (`repositories/`):** Satu-satunya lapisan yang diizinkan berkomunikasi dengan `FirebaseFirestore`, `FirebaseAuth`, dan `SharedPreferences`.
* **Aturan Akses Database & Transaksi Stok:**
  * Pembuatan pesanan (`orders`) dan pembatalan pesanan (`cancelled`) **WAJIB** menggunakan `FirebaseFirestore.instance.runTransaction()` di dalam `OrderRepository` untuk menjamin pembacaan dan pengurangan/pengembalian `menus.stok` berjalan secara atomik.
  * Antrean pesanan di layar Dapur (*Kitchen*) **WAJIB** diurutkan secara FIFO berdasarkan `waktuPesan` ascending (`orderBy('waktuPesan', descending: false)`).
  * Gunakan `FieldValue.serverTimestamp()` untuk mengisi field `waktuPesan` dan `updatedAt`.
* **Pencarian & Preferensi Lokal:**
  * Fitur pencarian nama menu dan nomor meja wajib menggunakan objek `RegExp(query, caseSensitive: false)` pada repositori atau *provider* sesuai spesifikasi praktikum.
  * Preferensi Mode Gelap (*Dark Mode*) wajib disimpan ke `SharedPreferences` dengan key `'pref_dark_mode'` dan langsung dihubungkan ke `ThemeData` pada root `MaterialApp`.
* **Konfigurasi Lingkungan:**
  * Gunakan `lib/firebase_options.dart` untuk konfigurasi Firebase dan `--dart-define` jika membutuhkan variabel lingkungan tambahan. Jangan pernah menanamkan kredensial rahasia secara *hardcoded* di dalam kode UI.

---

## 4. Error Handling & Security

* **Standar Try-Catch & Async Safety:**
  * Seluruh operasi I/O asinkron (Firestore, Auth, Kamera, SharedPreferences) di dalam `repositories/` wajib dibungkus dalam blok `try-catch` yang menangkap `FirebaseException` secara spesifik sebelum `Exception` umum, lalu melempar pesan error yang ramah pengguna.
  * Di lapisan UI (`StatefulWidget`), **WAJIB** memeriksa `if (!context.mounted) return;` sebelum memanggil `Navigator` atau `ScaffoldMessenger.of(context)` setelah pemanggilan `await`.
* **Validasi Input Ketat:**
  * **QR Code Meja:** Wajib divalidasi dengan pola RegExp `^MEJA-\d{2}$` sebelum menyimpan sesi meja pelanggan.
  * **Formulir Menu & Stok:** Gunakan `GlobalKey<FormState>()` dan fungsi validator di `lib/core/utils/validators.dart` (Nama $\ge 3$ karakter, Harga $> 0$, Stok $\ge 0$, Batas Minimum $\ge 0$).
  * **State Machine Pesanan:** Validasi transisi status pesanan secara ketat (`pending_payment` $\rightarrow$ `in_kitchen` $\rightarrow$ `ready` $\rightarrow$ `completed`, dan `pending_payment` $\rightarrow$ `cancelled`). Tolak semua lompatan status di luar aturan ini.
* **Role-Based Access Control (RBAC):**
  * Pastikan setiap layar staf memeriksa `UserModel.role` (`'kasir'`, `'kitchen'`, `'manager'`) dari `AuthProvider`. Pelanggan (*Guest*) hanya boleh mengakses alur pemesanan QR dan layar status pesanannya sendiri.
* **Logging:**
  * Gunakan `debugPrint()` dari `package:flutter/foundation.dart` untuk pencatatan log saat pengembangan. **DILARANG** menggunakan `print()` bawaan Dart di kode produksi.

---

## 5. Strict Do's and Don'ts

### DO's (Wajib Dilakukan)
* **DO:** Tulis kode secara lengkap, fungsional, dan langsung siap dikompilasi (*production-ready*).
* **DO:** Tangani ketiga kondisi state pada setiap `StreamBuilder` dan `FutureBuilder`: `ConnectionState.waiting` (*loading indicator*), ` snapshot.hasError` (*error state*), dan data kosong (*empty state widget*).
* **DO:** Simpan snapshot `nama` dan `harga` satuan menu ke dalam array `items` pada dokumen `orders` saat checkout agar perubahan harga menu di masa depan tidak merusak histori pendapatan.
* **DO:** Bebaskan memori controller (`TextEditingController`, `MobileScannerController`) di dalam method `dispose()` pada setiap `StatefulWidget`.

### DON'Ts (Larangan Keras)
* **DON'T:** **JANGAN** mengubah nama koleksi/field database (`users`, `menus`, `orders`) yang sudah ditetapkan di `PRD.md` dan `schema.sql` tanpa izin eksplisit.
* **DON'T:** **JANGAN** menginstal paket/library pihak ketiga baru di `pubspec.yaml` jika fungsinya sudah tersedia di SDK bawaan Flutter/Dart atau paket yang telah disetujui.
* **DON'T:** **JANGAN** menulis komentar *placeholder* seperti `// TODO: implement logic here`, `// ... existing code ...`, atau memotong implementasi fungsi saat diminta menulis/memperbarui kode.
* **DON'T:** **JANGAN** menghapus komentar dokumentasi penting atau aturan bisnis yang sudah tertulis di dalam kode.
* **DON'T:** **JANGAN** mengurangi atau menambah `menus.stok` saat transaksi pesanan menggunakan `.update()` biasa di luar `runTransaction()`.

---

## 6. Common Commands

Gunakan perintah terminal standar berikut untuk siklus pengembangan, analisis kualitas kode, dan proses *build*:

```bash
# 1. Mengunduh seluruh dependensi paket Flutter
flutter pub get

# 2. Menjalankan analisis statis & linter (wajib 0 error/warning sebelum commit)
flutter analyze

# 3. Merapikan format kode sesuai standar Dart
dart format lib/

# 4. Menjalankan aplikasi dalam mode debug
flutter run

# 5. Menjalankan pengujian unit & widget test
flutter test

# 6. Membersihkan cache build jika terjadi konflik dependensi
flutter clean && flutter pub get

# 7. Mem-build file APK rilis untuk perangkat Android
flutter build apk --release

# 8. Men-deploy aturan keamanan & composite index Firestore (jika menggunakan Firebase CLI)
firebase deploy --only firestore:rules,firestore:indexes
```