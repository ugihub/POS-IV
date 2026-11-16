# Product Requirements Document (PRD)
**Nama Proyek:** Aplikasi Mobile POS, Kitchen Display System (KDS), dan Monitoring Rantai Pasok Internal Berbasis QR Table  
**Platform:** Mobile (Android/iOS) — Flutter & Dart  
**Backend & Database:** Firebase (Cloud Firestore & Firebase Authentication)  
**Target Rilis:** MVP (Tugas Proyek Akhir Modul 12)  

---

## 1. Project Overview & Objectives

### 1.1 Ringkasan Sistem
Aplikasi mobile *multi-role* berbasis Flutter yang mengintegrasikan proses pemesanan pelanggan di meja (*QR Table Ordering*), verifikasi transaksi kasir (*Point of Sale*), alur produksi dapur (*Kitchen Display System*), dan pemantauan stok operasional oleh manajer dalam satu ekosistem data *real-time*.

### 1.2 Permasalahan Utama yang Diselesaikan
1. **Hambatan Aliran Informasi (*Order Fulfillment Bottleneck*):** Keterlambatan dan kesalahan pencatatan pesanan serta nomor meja antara bagian depan (kasir/pelanggan) dan dapur.
2. **Ketidaksinkronan Stok (*Inventory Blindspot*):** Terjadinya *over-selling* (pelanggan memesan menu yang bahannya sudah habis) karena pembaruan status stok di dapur tidak langsung tercermin pada daftar menu kasir/pelanggan.
3. **Kurangnya Visibilitas Operasional:** Manajer kesulitan memantau beban antrean dapur, performa pemenuhan pesanan, dan peringatan stok menipis secara *real-time*.

### 1.3 Tujuan Utama (*Objectives*)
* Menciptakan aliran distribusi pesanan (*demand flow*) tanpa jeda dari meja pelanggan $\rightarrow$ kasir $\rightarrow$ dapur menggunakan sinkronisasi *real-time* Cloud Firestore.
* Menerapkan pengurangan dan penguncian stok menu secara otomatis (*atomic transaction*) untuk mencegah pesanan fiktif atau kehabisan stok mendadak.
* Menyediakan antarmuka pemantauan ringkas bagi manajer untuk pengambilan keputusan pengadaan ulang (*restock*) dan evaluasi operasional harian.

---

## 2. User Roles & Permissions

Sistem menggunakan arsitektur **Single-App Multi-Role** dengan pembagian hak akses sebagai berikut:

| Peran (*Role*) | Metode Akses | Hak Akses & Wewenang (*Permissions*) |
| :--- | :--- | :--- |
| **Customer (Pelanggan)** | *Guest Mode* (Tanpa Login, via Scan QR Meja) | • Memindai QR Code nomor meja.<br>• Membaca katalog `menus` (item stok `0` terkunci).<br>• Membuat dokumen `orders` baru (`status: pending_payment`).<br>• Melihat status pesanan aktif miliknya secara *real-time*. |
| **Kasir** | Firebase Auth (`role: 'kasir'`) | • Membaca katalog `menus` & daftar `orders`.<br>• Membuat pesanan *walk-in* (input manual di kasir).<br>• Mengubah `orders.status` dari `pending_payment` $\rightarrow$ `in_kitchen` (konfirmasi bayar) atau `cancelled` (batal). |
| **Kitchen (Dapur)** | Firebase Auth (`role: 'kitchen'`) | • Membaca daftar `orders` berstatus `in_kitchen` dan `ready`.<br>• Mengubah `orders.status` (`in_kitchen` $\rightarrow$ `ready` $\rightarrow$ `completed`).<br>• Mengubah nilai `menus.stok` secara langsung jika bahan habis di tengah operasional. |
| **Manager** | Firebase Auth (`role: 'manager'`) | • Full CRUD pada koleksi `menus` (tambah, ubah, hapus, atur stok & batas minimum).<br>• Membaca seluruh riwayat `orders` dan metrik ringkasan harian.<br>• Melihat daftar peringatan stok menipis (*low stock alerts*). |

*Catatan: Seluruh peran memiliki akses ke pengaturan lokal aplikasi untuk mengubah preferensi tema (Light/Dark Mode).*

---

## 3. Core Features & User Flows

### 3.1 QR Table Ordering (Pelanggan)
* **Deskripsi:** Pemesanan mandiri dari meja menggunakan kamera perangkat untuk mendeteksi nomor meja secara otomatis.
* **User Flow:**
  1. Pelanggan membuka aplikasi dan memilih tombol **"Pesan via QR Meja"**.
  2. Aplikasi membuka pemindai kamera (`mobile_scanner`) dan membaca string QR (contoh: `MEJA-04`).
  3. Sistem memvalidasi format QR dan menyimpan nomor meja ke dalam *state* sesi.
  4. Pelanggan melihat katalog menu, dapat mencari menu menggunakan kata kunci, dan menambahkan item ke keranjang (*cart*).
  5. Pelanggan menekan **"Kirim Pesanan"**. Sistem memvalidasi stok, mengurangi stok di database, menyimpan pesanan dengan status `pending_payment`, dan menampilkan layar instruksi pembayaran ke kasir beserta status pesanan *real-time*.

### 3.2 Verifikasi Transaksi & Kasir POS (Kasir)
* **Deskripsi:** Gerbang validasi pembayaran sebelum pesanan diteruskan ke antrean produksi dapur, sekaligus mendukung input pesanan *walk-in*.
* **User Flow:**
  1. Kasir login menggunakan akun ber-role `kasir`.
  2. Dashboard kasir menampilkan tab **"Menunggu Bayar"** (`pending_payment`) dan tab **"Input Pesanan Baru"**.
  3. Untuk pesanan QR masuk: Pelanggan membayar secara tunai/QRIS statis di meja kasir $\rightarrow$ Kasir memilih pesanan terkait $\rightarrow$ Menekan **"Konfirmasi Pembayaran"**.
  4. Status pesanan berubah menjadi `in_kitchen` dan otomatis muncul di layar dapur.
  5. Jika pelanggan belum membayar dalam batas waktu tertentu atau membatalkan pesanan, kasir menekan **"Batalkan Pesanan"** untuk mengembalikan stok menu.

### 3.3 Kitchen Display System & Kontrol Stok (Dapur)
* **Deskripsi:** Layar antrean produksi dapur berbasis urutan waktu masuk (FIFO) dan kontrol ketersediaan stok cepat.
* **User Flow:**
  1. Staf dapur login menggunakan akun ber-role `kitchen`.
  2. Layar utama menampilkan daftar pesanan berstatus `in_kitchen` yang diurutkan dari waktu pesan paling lama (FIFO).
  3. Staf dapur memproses pesanan dan menekan tombol **"Siap Diantar"** (`ready`), lalu menekan **"Selesai"** (`completed`) setelah hidangan diambil pelayan.
  4. Melalui tab **"Stok Menu"**, staf dapur dapat langsung mengurangi/menolkan stok menu jika stok fisik habis saat jam operasional.

### 3.4 Monitoring Operasional & Manajemen Menu (Manajer)
* **Deskripsi:** Pusat kendali inventaris menu dan pemantauan kelancaran distribusi pesanan.
* **User Flow:**
  1. Manajer login menggunakan akun ber-role `manager`.
  2. Halaman Dashboard menampilkan ringkasan KPI harian: Total Pendapatan (`completed`), Jumlah Antrean Aktif di Dapur (`in_kitchen`), dan Daftar Peringatan Stok Menipis.
  3. Pada tab **"Kelola Menu"**, manajer dapat menambah menu baru, mengedit harga, atau melakukan *restock* jumlah stok.
  4. Pada tab **"Riwayat Transaksi"**, manajer dapat memfilter dan mencari riwayat pesanan berdasarkan nomor meja atau ID pesanan.

### 3.5 Preferensi Tema Aplikasi (Dark/Light Mode)
* **Deskripsi:** Pengaturan tampilan gelap/terang yang tersimpan secara lokal pada perangkat (sangat berguna untuk mengurangi silau layar di area dapur).
* **User Flow:**
  1. Pengguna menekan ikon *switch* tema pada *AppBar* atau halaman pengaturan.
  2. Aplikasi menyimpan nilai boolean `isDarkMode` menggunakan `shared_preferences` dan langsung memperbarui `ThemeData` aplikasi secara global.

---

## 4. Functional Requirements

### 4.1 Spesifikasi Teknologi & Paket Flutter
* **State Management:** `provider` atau `riverpod`
* **Firebase SDK:** `firebase_core`, `firebase_auth`, `cloud_firestore`
* **QR Scanner:** `mobile_scanner`
* **Local Storage:** `shared_preferences`

### 4.2 Struktur Database (Cloud Firestore)
1. **Collection `users`**
   * `uid` (String): Document ID dari Firebase Auth
   * `nama` (String): Nama lengkap staf
   * `email` (String): Email login
   * `role` (String): `'kasir'` | `'kitchen'` | `'manager'`
2. **Collection `menus`**
   * `menuId` (String): Document ID
   * `nama` (String): Nama makanan/minuman
   * `kategori` (String): `'Makanan'` | `'Minuman'` | `'Snack'`
   * `harga` (Number): Harga satuan dalam Rupiah
   * `stok` (Number): Jumlah ketersediaan stok saat ini
   * `batasMinimum` (Number): Ambang batas peringatan *low stock*
3. **Collection `orders`**
   * `orderId` (String): Document ID
   * `nomorMeja` (String): Contoh `'MEJA-01'` atau `'WALK-IN'`
   * `items` (Array of Map): `[{ "menuId": String, "nama": String, "qty": Number, "harga": Number }]`
   * `totalHarga` (Number): Total akumulasi harga pesanan
   * `status` (String): `'pending_payment'` | `'in_kitchen'` | `'ready'` | `'completed'` | `'cancelled'`
   * `waktuPesan` (Timestamp): Waktu server saat pesanan dibuat (`FieldValue.serverTimestamp()`)

### 4.3 Aturan Bisnis (*Business Logic*)
* **State Machine Status Pesanan:**
  * Transisi valid hanya berjalan searah: `pending_payment` $\rightarrow$ `in_kitchen` $\rightarrow$ `ready` $\rightarrow$ `completed`.
  * Status `cancelled` hanya dapat dipicu dari status `pending_payment`.
* **Atomic Stock Transaction:**
  * Pembuatan pesanan (`orders`) **wajib** menggunakan `FirebaseFirestore.instance.runTransaction()`.
  * Di dalam transaksi, sistem membaca `menus.stok` terkini untuk setiap item di keranjang. Jika seluruh item memenuhi $\text{stok} \ge \text{qty}$, sistem mengurangi `menus.stok` sebesar `qty` dan membuat dokumen `orders` secara bersamaan.
  * Jika pesanan dibatalkan (`cancelled`), sistem wajib menjalankan transaksi untuk mengembalikan (`increment`) `menus.stok` sejumlah `qty` item pada pesanan tersebut.
* **Antrean Dapur FIFO:**
  * Query Firestore pada layar *Kitchen* wajib mengurutkan data berdasarkan `waktuPesan` secara *ascending* (`orderBy('waktuPesan', descending: false)`).

### 4.4 Validasi Input (*Input Validation*)
* **Validasi QR Meja:** String hasil pemindaian kamera wajib lolos pola ekspresi reguler `^MEJA-\d{2}$` (contoh: `MEJA-01` hingga `MEJA-99`).
* **Validasi Form Menu (Manajer):**
  * `nama`: Wajib diisi, minimal 3 karakter.
  * `harga`: Wajib diisi, angka positif ($> 0$).
  * `stok`: Wajib diisi, bilangan bulat non-negatif ($\ge 0$).
  * `batasMinimum`: Wajib diisi, bilangan bulat non-negatif ($\ge 0$).
* **Validasi Keranjang Pesanan:**
  * Keranjang tidak boleh kosong ($\text{jumlah item} \ge 1$).
  * Kuantitas setiap item wajib memenuhi $1 \le \text{qty} \le \text{stok}$.

### 4.5 Kalkulasi & Algoritma Spesifik
* **Subtotal Item:**
  $$\text{subtotal}_i = \text{harga}_i \times \text{qty}_i$$
* **Total Harga Pesanan:**
  $$\text{totalHarga} = \sum_{i=1}^{n} (\text{harga}_i \times \text{qty}_i)$$
* **Indikator Ketersediaan Menu:**
  $$\text{isAvailable} = (\text{stok} > 0)$$
* **Indikator Peringatan Stok Menipis (*Low Stock*):**
  $$\text{isLowStock} = (\text{stok} \le \text{batasMinimum})$$
* **Algoritma Pencarian (*Search Filter*):**
  * Menggunakan `RegExp(query, caseSensitive: false)` pada repositori/state untuk menyaring daftar berdasarkan `menus.nama` atau `orders.nomorMeja`.

---

## 5. Scope & Limitations

### 5.1 In-Scope (MVP)
* Aplikasi mobile Flutter tunggal dengan akses *Guest* (Pelanggan) dan *Role-Based Login* (Kasir, Kitchen, Manager).
* Pemindaian QR Code berbasis teks sederhana untuk identifikasi nomor meja.
* Sinkronisasi status pesanan dan stok menu secara *real-time* menggunakan Firestore `StreamBuilder`.
* Konfirmasi pembayaran manual oleh kasir.
* CRUD katalog menu, pengaturan batas stok minimum, dan peringatan *low stock*.
* Pencarian berbasis `RegExp` dan penyimpanan preferensi *Dark Mode* menggunakan `shared_preferences`.

### 5.2 Out-of-Scope (Ditunda di Luar MVP)
* Integrasi *Payment Gateway* otomatis (Midtrans, Xendit, atau verifikasi mutasi QRIS otomatis).
* Pencetakan struk fisik via printer termal Bluetooth.
* Konversi resep bahan baku tingkat lanjut (*Bill of Materials* / gramasi bahan mentah; sistem menghitung stok per porsi menu jadi).
* Manajemen multi-cabang restoran.
* *Push notification* latar belakang via Firebase Cloud Messaging (FCM); notifikasi mengandalkan pembaruan tampilan *real-time* saat aplikasi terbuka.

---

## 6. Edge Cases & Error Handling

| Skenario Gagal (*Edge Case*) | Penanganan Sistem (*Error Handling*) |
| :--- | :--- |
| **Race Condition Stok Habis:** Dua meja memesan sisa 1 porsi menu yang sama secara bersamaan. | Firestore `runTransaction` menolak transaksi kedua saat mendeteksi $\text{stok} < \text{qty}$. Sistem menampilkan pesan *dialog/snackbar* bahwa stok item baru saja habis dan meminta pelanggan memperbarui keranjang. |
| **QR Code Tidak Valid:** Pelanggan memindai QR Code lain (misal: URL website atau QR Wi-Fi) yang tidak sesuai format. | Validasi regex `^MEJA-\d{2}$` gagal. Pemindai tidak *crash*, menampilkan pesan peringatan *"Kode QR meja tidak valid"*, dan tetap siap memindai ulang. |
| **Izin Kamera Ditolak:** Pelanggan menolak akses kamera saat membuka fitur *Scan QR*. | Menampilkan halaman fallback informatif beserta tombol untuk membuka pengaturan izin aplikasi perangkat (`openAppSettings()`). |
| **Pesanan QR Terbengkalai:** Pelanggan mengirim pesanan via QR (stok sudah berkurang), tetapi tidak pernah membayar ke kasir. | Kasir dapat menekan tombol **"Batalkan Pesanan"** pada daftar `pending_payment` untuk mengubah status ke `cancelled` dan mengembalikan stok menu ke inventaris secara otomatis. |
| **Koneksi Internet Terputus:** Perangkat kehilangan sinyal saat mengirim pesanan atau mengubah status. | Menampilkan indikator status koneksi/loading yang jelas, menangkap *exception* timeout Firebase, dan menampilkan pesan *"Koneksi terputus, silakan coba lagi"* tanpa menghapus isi keranjang lokal pengguna. |
| **Data Kosong / State Loading:** Belum ada pesanan di antrean dapur atau hasil pencarian `RegExp` tidak ditemukan. | `StreamBuilder` menangani status `ConnectionState.waiting` dengan *loading spinner*, `hasError` dengan pesan error informatif, dan daftar kosong dengan ilustrasi/teks *empty state* yang sesuai. |