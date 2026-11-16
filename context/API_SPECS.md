# API Specification Document
**Nama Proyek:** Aplikasi Mobile POS, Kitchen Display System (KDS), dan Monitoring Rantai Pasok Internal Berbasis QR Table  
**Base URL:** `/api/v1`  
**Content-Type:** `application/json`  
**Autentikasi:** `Bearer <JWT_TOKEN / FIREBASE_ID_TOKEN>` pada header `Authorization`  

---

## Standar Konvensi Format Response

Seluruh endpoint menggunakan amplop JSON standar berikut:

* **Format Sukses (`200 OK` / `201 Created`):**
```json
{
  "success": true,
  "message": "Deskripsi singkat operasi berhasil",
  "data": {}
}
```

* **Format Error (`400`, `401`, `403`, `404`, `409`, `422`, `500`):**
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE_IDENTIFIER",
    "message": "Pesan error yang dapat ditampilkan ke pengguna",
    "details": {}
  }
}
```

---

## Modul 1: Autentikasi & Sesi Meja (`Auth & Table Session`)

### 1.1 Login Staf Operasional
* **Method & URL Path:** `POST /api/v1/auth/login`
* **Deskripsi & Auth Requirement:** Autentikasi staf internal untuk mendapatkan token akses beserta data peran (`kasir`, `kitchen`, `manager`). **Auth:** *Public* (Tanpa Token).
* **Request Payload (JSON Body):**
```json
{
  "email": "string (required, valid email)",
  "password": "string (required, min 6 chars)"
}
```
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Login berhasil",
    "data": {
      "token": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",
      "user": {
        "uid": "usr_98234792",
        "nama": "Budi Santoso",
        "email": "kasir1@resto.com",
        "role": "kasir"
      }
    }
  }
  ```
  * **Error (`401 Unauthorized`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "INVALID_CREDENTIALS",
      "message": "Email atau kata sandi salah."
    }
  }
  ```

---

### 1.2 Ambil Profil Staf Aktif
* **Method & URL Path:** `GET /api/v1/auth/me`
* **Deskripsi & Auth Requirement:** Memverifikasi sesi token aktif dan mengambil detail role pengguna saat aplikasi dibuka. **Auth:** *Bearer Token* (`kasir` | `kitchen` | `manager`).
* **Request Payload / Query Params:** Tidak ada.
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Data profil ditemukan",
    "data": {
      "uid": "usr_98234792",
      "nama": "Budi Santoso",
      "email": "kasir1@resto.com",
      "role": "kasir",
      "created_at": "2026-11-01T08:00:00Z"
    }
  }
  ```
  * **Error (`401 Unauthorized`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "UNAUTHORIZED",
      "message": "Sesi telah berakhir, silakan login kembali."
    }
  }
  ```

---

### 1.3 Validasi Kode QR Meja Pelanggan
* **Method & URL Path:** `POST /api/v1/auth/validate-qr`
* **Deskripsi & Auth Requirement:** Memvalidasi string hasil pindaian kamera terhadap pola `^MEJA-\d{2}$` sebelum menginisialisasi sesi pemesanan pelanggan. **Auth:** *Public / Guest* (Tanpa Token).
* **Request Payload (JSON Body):**
```json
{
  "qr_string": "string (required, contoh: 'MEJA-05')"
}
```
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Nomor meja valid",
    "data": {
      "nomor_meja": "MEJA-05",
      "session_valid": true
    }
  }
  ```
  * **Error (`422 Unprocessable Entity`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "INVALID_QR_FORMAT",
      "message": "Kode QR meja tidak valid. Gunakan format MEJA-01 hingga MEJA-99."
    }
  }
  ```

---

## Modul 2: Katalog & Inventaris Menu (`Menus & Stock`)

### 2.1 Daftar Katalog Menu & Pencarian RegExp
* **Method & URL Path:** `GET /api/v1/menus`
* **Deskripsi & Auth Requirement:** Mengambil daftar menu beserta status stok terkini. Mendukung filter kategori dan pencarian nama menggunakan ekspresi reguler (`RegExp`). **Auth:** *Public / Guest* dan seluruh *Role Staf*.
* **Query Params:**
  * `search` *(string, optional)*: Pola kata kunci pencarian nama menu (*case-insensitive* RegExp).
  * `kategori` *(string, optional)*: Filter berdasarkan `'Makanan'` | `'Minuman'` | `'Snack'`.
  * `low_stock_only` *(boolean, optional)*: Jika `true`, hanya mengembalikan menu dengan $\text{stok} \le \text{batas\_minimum}$.
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Daftar menu berhasil diambil",
    "data": [
      {
        "menu_id": "mnu_001",
        "nama": "Nasi Goreng Spesial",
        "kategori": "Makanan",
        "harga": 25000,
        "stok": 12,
        "batas_minimum": 5,
        "is_available": true,
        "is_low_stock": false,
        "updated_at": "2026-11-16T10:15:00Z"
      },
      {
        "menu_id": "mnu_002",
        "nama": "Es Kopi Susu Aren",
        "kategori": "Minuman",
        "harga": 18000,
        "stok": 0,
        "batas_minimum": 5,
        "is_available": false,
        "is_low_stock": true,
        "updated_at": "2026-11-16T11:30:00Z"
      }
    ]
  }
  ```
  * **Error (`400 Bad Request`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "INVALID_REGEX_PATTERN",
      "message": "Pola pencarian tidak valid."
    }
  }
  ```

---

### 2.2 Tambah Menu Baru
* **Method & URL Path:** `POST /api/v1/menus`
* **Deskripsi & Auth Requirement:** Menambahkan item menu baru beserta stok awal dan ambang batas stok minimum. **Auth:** *Bearer Token* (Role: `manager`).
* **Request Payload (JSON Body):**
```json
{
  "nama": "string (required, min 3 chars, unique)",
  "kategori": "string (required, enum: 'Makanan' | 'Minuman' | 'Snack')",
  "harga": "number (required, > 0)",
  "stok": "integer (required, >= 0)",
  "batas_minimum": "integer (required, >= 0)"
}
```
* **Response Format:**
  * **Success (`201 Created`):**
  ```json
  {
    "success": true,
    "message": "Menu berhasil ditambahkan",
    "data": {
      "menu_id": "mnu_003",
      "nama": "Mie Goreng Jawa",
      "kategori": "Makanan",
      "harga": 22000,
      "stok": 20,
      "batas_minimum": 5,
      "is_active": true,
      "updated_at": "2026-11-16T12:00:00Z"
    }
  }
  ```
  * **Error (`409 Conflict` / `422 Unprocessable Entity`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "VALIDATION_ERROR",
      "message": "Validasi input gagal",
      "details": {
        "nama": "Nama menu sudah terdaftar atau kurang dari 3 karakter",
        "harga": "Harga harus lebih besar dari 0"
      }
    }
  }
  ```

---

### 2.3 Perbarui Detail Menu
* **Method & URL Path:** `PUT /api/v1/menus/:menu_id`
* **Deskripsi & Auth Requirement:** Mengubah informasi nama, kategori, harga, stok, atau batas minimum menu. **Auth:** *Bearer Token* (Role: `manager`).
* **Request Payload (JSON Body):**
```json
{
  "nama": "string (required, min 3 chars)",
  "kategori": "string (required, enum: 'Makanan' | 'Minuman' | 'Snack')",
  "harga": "number (required, > 0)",
  "stok": "integer (required, >= 0)",
  "batas_minimum": "integer (required, >= 0)",
  "is_active": "boolean (optional, default: true)"
}
```
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Data menu berhasil diperbarui",
    "data": {
      "menu_id": "mnu_003",
      "nama": "Mie Goreng Jawa Spesial",
      "kategori": "Makanan",
      "harga": 24000,
      "stok": 25,
      "batas_minimum": 5,
      "is_active": true,
      "updated_at": "2026-11-16T12:30:00Z"
    }
  }
  ```
  * **Error (`404 Not Found`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "MENU_NOT_FOUND",
      "message": "Menu dengan ID mnu_003 tidak ditemukan."
    }
  }
  ```

---

### 2.4 Update Cepat Stok Menu (`Quick Stock Adjustment`)
* **Method & URL Path:** `PATCH /api/v1/menus/:menu_id/stock`
* **Deskripsi & Auth Requirement:** Mengubah jumlah stok secara langsung (misalnya menolkan stok dari dapur saat bahan habis atau *restock* oleh manajer) sekaligus mencatat riwayat di `stock_logs`. **Auth:** *Bearer Token* (Role: `kitchen` | `manager`).
* **Request Payload (JSON Body):**
```json
{
  "stok_baru": "integer (required, >= 0)",
  "keterangan": "string (required, contoh: 'KITCHEN_OUT_OF_STOCK' | 'RESTOCK_MANAGER')"
}
```
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Stok menu berhasil diperbarui",
    "data": {
      "menu_id": "mnu_001",
      "nama": "Nasi Goreng Spesial",
      "stok_sebelumnya": 12,
      "stok_akhir": 0,
      "perubahan_qty": -12,
      "is_low_stock": true,
      "updated_at": "2026-11-16T13:00:00Z"
    }
  }
  ```
  * **Error (`403 Forbidden`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "FORBIDDEN_ROLE",
      "message": "Akses ditolak. Hanya staf Kitchen dan Manager yang dapat mengubah stok."
    }
  }
  ```

---

### 2.5 Hapus Menu
* **Method & URL Path:** `DELETE /api/v1/menus/:menu_id`
* **Deskripsi & Auth Requirement:** Menghapus item menu dari sistem. Ditolak jika menu sudah memiliki riwayat transaksi di `order_items` (`ON DELETE RESTRICT`). **Auth:** *Bearer Token* (Role: `manager`).
* **Request Payload / Query Params:**Path param `menu_id` *(string, required)*.
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Menu berhasil dihapus",
    "data": {
      "deleted_menu_id": "mnu_099"
    }
  }
  ```
  * **Error (`409 Conflict`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "MENU_HAS_TRANSACTIONS",
      "message": "Menu tidak dapat dihapus karena memiliki riwayat transaksi. Gunakan fitur nonaktifkan menu."
    }
  }
  ```

---

## Modul 3: Pemesanan & Distribusi Dapur (`POS & Kitchen Display System`)

### 3.1 Buat Pesanan Baru (`Atomic Stock Deduction`)
* **Method & URL Path:** `POST /api/v1/orders`
* **Deskripsi & Auth Requirement:** Membuat transaksi pesanan baru. Sistem menjalankan *atomic database transaction* untuk memeriksa kecukupan stok ($\text{stok} \ge \text{qty}$), mengurangi `menus.stok`, dan menyimpan snapshot harga item.
  * **Auth:** *Public / Guest* (untuk `nomor_meja: 'MEJA-XX'` dengan status awal `'pending_payment'`) atau *Bearer Token* Role `kasir` (untuk `nomor_meja: 'WALK-IN'`).
* **Request Payload (JSON Body):**
```json
{
  "nomor_meja": "string (required, 'WALK-IN' atau sesuai regex '^MEJA-[0-9]{2}$')",
  "direct_pay": "boolean (optional, hanya berlaku jika dipanggil oleh role 'kasir', langsung set status 'in_kitchen')",
  "items": [
    {
      "menu_id": "string (required)",
      "qty": "integer (required, >= 1)"
    }
  ]
}
```
* **Response Format:**
  * **Success (`201 Created`):**
  ```json
  {
    "success": true,
    "message": "Pesanan berhasil dibuat",
    "data": {
      "order_id": "ord_20261116_001",
      "nomor_meja": "MEJA-05",
      "status": "pending_payment",
      "total_harga": 68000,
      "items": [
        {
          "menu_id": "mnu_001",
          "nama_menu_snapshot": "Nasi Goreng Spesial",
          "harga_satuan_snapshot": 25000,
          "qty": 2,
          "subtotal": 50000
        },
        {
          "menu_id": "mnu_002",
          "nama_menu_snapshot": "Es Kopi Susu Aren",
          "harga_satuan_snapshot": 18000,
          "qty": 1,
          "subtotal": 18000
        }
      ],
      "waktu_pesan": "2026-11-16T13:10:00Z"
    }
  }
  ```
  * **Error (`409 Conflict` - Race Condition Stok Habis):**
  ```json
  {
    "success": false,
    "error": {
      "code": "INSUFFICIENT_STOCK",
      "message": "Stok menu tidak mencukupi, silakan perbarui keranjang Anda.",
      "details": {
        "menu_id": "mnu_001",
        "nama": "Nasi Goreng Spesial",
        "requested_qty": 2,
        "available_stok": 1
      }
    }
  }
  ```

---

### 3.2 Daftar Antrean & Riwayat Pesanan
* **Method & URL Path:** `GET /api/v1/orders`
* **Deskripsi & Auth Requirement:** Mengambil daftar pesanan untuk layar Kasir (`pending_payment`), layar antrean FIFO Dapur (`in_kitchen`, `ready`), dan layar Riwayat Manajer. **Auth:** *Bearer Token* (Role: `kasir` | `kitchen` | `manager`).
* **Query Params:**
  * `status` *(string, optional)*: Filter satu atau beberapa status dipisahkan koma (contoh: `status=in_kitchen,ready`).
  * `nomor_meja` *(string, optional)*: Pencarian RegExp berdasarkan nomor meja (contoh: `MEJA-05`).
  * `sort` *(string, optional)*: `'fifo'` (`waktu_pesan ASC` untuk antrean dapur) atau `'latest'` (`waktu_pesan DESC` untuk riwayat transaksi).
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Daftar pesanan berhasil diambil",
    "data": [
      {
        "order_id": "ord_20261116_001",
        "nomor_meja": "MEJA-05",
        "total_harga": 68000,
        "status": "in_kitchen",
        "verified_by_uid": "usr_98234792",
        "waktu_pesan": "2026-11-16T13:10:00Z",
        "waktu_selesai": null,
        "items": [
          {
            "menu_id": "mnu_001",
            "nama_menu_snapshot": "Nasi Goreng Spesial",
            "harga_satuan_snapshot": 25000,
            "qty": 2,
            "subtotal": 50000
          }
        ]
      }
    ]
  }
  ```
  * **Error (`401 Unauthorized`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "UNAUTHORIZED",
      "message": "Token autentikasi tidak ditemukan."
    }
  }
  ```

---

### 3.3 Pantau Status Pesanan Pelanggan
* **Method & URL Path:** `GET /api/v1/orders/:order_id`
* **Deskripsi & Auth Requirement:** Mengambil status terkini dari satu pesanan spesifik untuk ditampilkan secara *real-time* pada layar tunggu pelanggan QR. **Auth:** *Public / Guest* dan seluruh *Role Staf*.
* **Request Payload / Query Params:** Path param `order_id` *(string, required)*.
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Detail pesanan ditemukan",
    "data": {
      "order_id": "ord_20261116_001",
      "nomor_meja": "MEJA-05",
      "status": "ready",
      "total_harga": 68000,
      "items": [
        {
          "menu_id": "mnu_001",
          "nama_menu_snapshot": "Nasi Goreng Spesial",
          "harga_satuan_snapshot": 25000,
          "qty": 2,
          "subtotal": 50000
        }
      ],
      "waktu_pesan": "2026-11-16T13:10:00Z",
      "waktu_selesai": null
    }
  }
  ```
  * **Error (`404 Not Found`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "ORDER_NOT_FOUND",
      "message": "Pesanan tidak ditemukan."
    }
  }
  ```

---

### 3.4 Verifikasi Pembayaran Kasir (`Confirm Payment`)
* **Method & URL Path:** `PATCH /api/v1/orders/:order_id/verify-payment`
* **Deskripsi & Auth Requirement:** Memvalidasi pembayaran pelanggan di kasir dan meneruskan pesanan ke layar antrean dapur (`pending_payment` $\rightarrow$ `in_kitchen`). **Auth:** *Bearer Token* (Role: `kasir`).
* **Request Payload (JSON Body):** Tidak memerlukan body (UID kasir diambil otomatis dari token).
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Pembayaran terverifikasi, pesanan diteruskan ke dapur",
    "data": {
      "order_id": "ord_20261116_001",
      "previous_status": "pending_payment",
      "status": "in_kitchen",
      "verified_by_uid": "usr_98234792"
    }
  }
  ```
  * **Error (`422 Unprocessable Entity` - Invalid State Transition):**
  ```json
  {
    "success": false,
    "error": {
      "code": "INVALID_STATUS_TRANSITION",
      "message": "Hanya pesanan berstatus 'pending_payment' yang dapat diverifikasi pembayarannya."
    }
  }
  ```

---

### 3.5 Batalkan Pesanan & Rollback Stok (`Cancel Order`)
* **Method & URL Path:** `PATCH /api/v1/orders/:order_id/cancel`
* **Deskripsi & Auth Requirement:** Membatalkan pesanan yang belum dibayar (`pending_payment` $\rightarrow$ `cancelled`) dan mengembalikan (`increment`) jumlah stok seluruh item di dalamnya secara atomik ke tabel `menus`. **Auth:** *Bearer Token* (Role: `kasir`).
* **Request Payload (JSON Body):**
```json
{
  "alasan_batal": "string (optional, contoh: 'Pelanggan membatalkan pesanan')"
}
```
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Pesanan dibatalkan dan stok menu telah dikembalikan",
    "data": {
      "order_id": "ord_20261116_001",
      "previous_status": "pending_payment",
      "status": "cancelled",
      "restored_items_count": 2
    }
  }
  ```
  * **Error (`422 Unprocessable Entity`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "CANNOT_CANCEL_PROCESSED_ORDER",
      "message": "Pesanan yang sudah masuk ke dapur tidak dapat dibatalkan."
    }
  }
  ```

---

### 3.6 Update Status Produksi Dapur (`Kitchen Status Update`)
* **Method & URL Path:** `PATCH /api/v1/orders/:order_id/kitchen-status`
* **Deskripsi & Auth Requirement:** Memperbarui status pengerjaan pesanan di dapur secara berurutan (`in_kitchen` $\rightarrow$ `ready` $\rightarrow$ `completed`). Saat berubah menjadi `completed`, sistem mengisi kolom `waktu_selesai`. **Auth:** *Bearer Token* (Role: `kitchen`).
* **Request Payload (JSON Body):**
```json
{
  "status": "string (required, enum: 'ready' | 'completed')"
}
```
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Status produksi pesanan diperbarui",
    "data": {
      "order_id": "ord_20261116_001",
      "nomor_meja": "MEJA-05",
      "previous_status": "in_kitchen",
      "status": "ready",
      "waktu_selesai": null
    }
  }
  ```
  * **Error (`422 Unprocessable Entity`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "INVALID_STATE_TRANSITION",
      "message": "Transisi status tidak valid. Pesanan harus berstatus 'ready' sebelum diubah menjadi 'completed'."
    }
  }
  ```

---

## Modul 4: Monitoring Manajer & Log Logistik (`Manager Analytics & Logs`)

### 4.1 Ringkasan Dashboard Operasional & Low Stock
* **Method & URL Path:** `GET /api/v1/analytics/dashboard`
* **Deskripsi & Auth Requirement:** Mengambil metrik KPI harian (total pendapatan dari pesanan `completed`, jumlah antrean aktif di dapur, dan daftar menu yang mengalami peringatan stok menipis). **Auth:** *Bearer Token* (Role: `manager`).
* **Query Params:**
  * `date` *(string, optional)*: Tanggal laporan dalam format `YYYY-MM-DD` (default: hari ini).
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Ringkasan dashboard berhasil dimuat",
    "data": {
      "tanggal": "2026-11-16",
      "kpi": {
        "total_pendapatan": 1450000,
        "total_pesanan_selesai": 32,
        "antrean_dapur_aktif": 4,
        "pesanan_menunggu_bayar": 2,
        "pesanan_dibatalkan": 1
      },
      "low_stock_alerts": [
        {
          "menu_id": "mnu_002",
          "nama": "Es Kopi Susu Aren",
          "kategori": "Minuman",
          "stok": 0,
          "batas_minimum": 5
        },
        {
          "menu_id": "mnu_005",
          "nama": "Kentang Goreng Crispy",
          "kategori": "Snack",
          "stok": 3,
          "batas_minimum": 5
        }
      ]
    }
  }
  ```
  * **Error (`403 Forbidden`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "FORBIDDEN_ROLE",
      "message": "Hanya Manager yang dapat mengakses metrik analitik."
    }
  }
  ```

---

### 4.2 Riwayat Mutasi Stok (`Audit Trail Logistik`)
* **Method & URL Path:** `GET /api/v1/stock-logs`
* **Deskripsi & Auth Requirement:** Mengambil riwayat keluar-masuk stok (`stock_logs`) untuk memantau ketertelusuran rantai pasok internal. **Auth:** *Bearer Token* (Role: `manager`).
* **Query Params:**
  * `menu_id` *(string, optional)*: Filter riwayat mutasi untuk satu menu tertentu.
  * `limit` *(integer, optional, default: 50)*: Batas jumlah baris log yang ditampilkan.
* **Response Format:**
  * **Success (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Riwayat mutasi stok berhasil diambil",
    "data": [
      {
        "log_id": 104,
        "menu_id": "mnu_001",
        "nama_menu": "Nasi Goreng Spesial",
        "changed_by_uid": null,
        "order_id": "ord_20261116_001",
        "perubahan_qty": -2,
        "stok_akhir": 10,
        "keterangan": "ORDER_CHECKOUT",
        "waktu_log": "2026-11-16T13:10:00Z"
      }
    ]
  }
  ```
  * **Error (`403 Forbidden`):**
  ```json
  {
    "success": false,
    "error": {
      "code": "FORBIDDEN_ROLE",
      "message": "Akses ditolak."
    }
  }
  ```