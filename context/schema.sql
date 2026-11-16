-- ============================================================================
-- DATABASE SCHEMA SPECIFICATION (SQL DDL & CLOUD FIRESTORE MAPPING)
-- Proyek : Aplikasi Mobile POS, KDS, dan Monitoring Rantai Pasok (QR Table)
-- Dialect: PostgreSQL / SQLite (Relational Reference & Local Persistence)
-- ============================================================================

-- Aktifkan dukungan Foreign Key (khusus jika dijalankan pada engine SQLite)
PRAGMA foreign_keys = ON;

-- ============================================================================
-- 1. TABEL USERS (Koleksi Firestore: `users`)
-- Menyimpan data akun staf internal dan hak akses (Role-Based Access Control).
-- Pelanggan (Guest QR) tidak disimpan di tabel ini karena bersifat tanpa login.
-- ============================================================================
CREATE TABLE users (
    uid VARCHAR(128) PRIMARY KEY, -- Menggunakan UID dari Firebase Authentication
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    role VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraint: Memastikan role hanya berisi 3 peran staf yang sah
    CONSTRAINT chk_users_role CHECK (role IN ('kasir', 'kitchen', 'manager')),
    -- Constraint: Nama staf minimal 3 karakter
    CONSTRAINT chk_users_nama_len CHECK (LENGTH(TRIM(nama)) >= 3)
);

COMMENT ON TABLE users IS 'Daftar akun staf operasional restoran (Kasir, Kitchen, Manager).';
COMMENT ON COLUMN users.uid IS 'Primary Key yang berkorespondensi langsung dengan Document ID Firebase Auth.';
COMMENT ON COLUMN users.role IS 'Penentu hak akses tampilan di aplikasi: kasir, kitchen, atau manager.';


-- ============================================================================
-- 2. TABEL MENUS (Koleksi Firestore: `menus`)
-- Menyimpan katalog produk makanan/minuman beserta posisi stok inventaris
-- dan ambang batas peringatan stok minimum (Low Stock Alert).
-- ============================================================================
CREATE TABLE menus (
    menu_id VARCHAR(64) PRIMARY KEY, -- Document ID pada koleksi `menus`
    nama VARCHAR(120) NOT NULL UNIQUE,
    kategori VARCHAR(30) NOT NULL,
    harga NUMERIC(12, 2) NOT NULL,
    stok INTEGER NOT NULL DEFAULT 0,
    batas_minimum INTEGER NOT NULL DEFAULT 5,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraint: Nama menu minimal 3 karakter (sesuai validasi Modul 7)
    CONSTRAINT chk_menus_nama_len CHECK (LENGTH(TRIM(nama)) >= 3),
    -- Constraint: Kategori menu yang diizinkan
    CONSTRAINT chk_menus_kategori CHECK (kategori IN ('Makanan', 'Minuman', 'Snack')),
    -- Constraint: Harga satuan wajib bernilai positif (> 0)
    CONSTRAINT chk_menus_harga_pos CHECK (harga > 0),
    -- Constraint: Stok dan batas minimum tidak boleh bernilai negatif (>= 0)
    CONSTRAINT chk_menus_stok_nonneg CHECK (stok >= 0),
    CONSTRAINT chk_menus_batas_nonneg CHECK (batas_minimum >= 0)
);

COMMENT ON TABLE menus IS 'Master katalog menu sekaligus pencatatan stok porsi siap jual.';
COMMENT ON COLUMN menus.stok IS 'Jumlah stok aktual yang dikurangi secara atomik saat pesanan dibuat.';
COMMENT ON COLUMN menus.batas_minimum IS 'Ambang batas pemicu indikator peringatan stok menipis (stok <= batas_minimum).';


-- ============================================================================
-- 3. TABEL ORDERS (Koleksi Firestore: `orders`)
-- Menyimpan header transaksi pemesanan baik dari scan QR meja maupun Walk-in,
-- serta melacak siklus hidup distribusi pesanan dari kasir ke dapur.
-- ============================================================================
CREATE TABLE orders (
    order_id VARCHAR(64) PRIMARY KEY, -- Document ID pada koleksi `orders`
    nomor_meja VARCHAR(15) NOT NULL,
    total_harga NUMERIC(12, 2) NOT NULL DEFAULT 0,
    status VARCHAR(25) NOT NULL DEFAULT 'pending_payment',
    verified_by_uid VARCHAR(128) NULL, -- UID Kasir yang memverifikasi pembayaran
    waktu_pesan TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    waktu_selesai TIMESTAMP WITH TIME ZONE NULL,

    -- Foreign Key ke tabel users (Kasir verifikator)
    CONSTRAINT fk_orders_verified_by
        FOREIGN KEY (verified_by_uid) REFERENCES users(uid)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    -- Constraint: Format nomor meja wajib 'MEJA-XX' (2 digit) atau 'WALK-IN'
    CONSTRAINT chk_orders_nomor_meja CHECK (
        nomor_meja = 'WALK-IN' OR nomor_meja ~ '^MEJA-[0-9]{2}$'
    ),
    -- Constraint: Total harga pesanan harus positif
    CONSTRAINT chk_orders_total_pos CHECK (total_harga > 0),
    -- Constraint: State machine status pesanan yang valid
    CONSTRAINT chk_orders_status CHECK (
        status IN ('pending_payment', 'in_kitchen', 'ready', 'completed', 'cancelled')
    )
);

COMMENT ON TABLE orders IS 'Data transaksi pesanan pelanggan dan status antrean pemenuhan di dapur.';
COMMENT ON COLUMN orders.nomor_meja IS 'Diisi otomatis dari hasil scan QR (MEJA-01 s/d MEJA-99) atau WALK-IN.';
COMMENT ON COLUMN orders.status IS 'Alur status: pending_payment -> in_kitchen -> ready -> completed (atau cancelled).';


-- ============================================================================
-- 4. TABEL ORDER_ITEMS (Sub-struktur Array `items` di dalam Dokumen `orders`)
-- Menyimpan rincian item menu yang dipesan pada setiap transaksi beserta
-- snapshot harga saat transaksi terjadi agar riwayat keuangan tidak berubah
-- meskipun harga menu di tabel `menus` diubah di kemudian hari.
-- ============================================================================
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id VARCHAR(64) NOT NULL,
    menu_id VARCHAR(64) NOT NULL,
    nama_menu_snapshot VARCHAR(120) NOT NULL, -- Snapshot nama menu saat dipesan
    harga_satuan_snapshot NUMERIC(12, 2) NOT NULL, -- Snapshot harga saat dipesan
    qty INTEGER NOT NULL,
    subtotal NUMERIC(12, 2) GENERATED ALWAYS AS (harga_satuan_snapshot * qty) STORED,

    -- Foreign Key ke tabel orders (Jika order dihapus, detail item ikut terhapus)
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    -- Foreign Key ke tabel menus (Mencegah penghapusan menu yang memiliki riwayat transaksi)
    CONSTRAINT fk_order_items_menu
        FOREIGN KEY (menu_id) REFERENCES menus(menu_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    -- Constraint: Tidak boleh ada duplikasi menu_id yang sama dalam 1 order_id
    CONSTRAINT uq_order_menu_item UNIQUE (order_id, menu_id),
    -- Constraint: Kuantitas pesanan wajib minimal 1 porsi
    CONSTRAINT chk_order_items_qty_pos CHECK (qty >= 1),
    -- Constraint: Snapshot harga wajib positif
    CONSTRAINT chk_order_items_harga_pos CHECK (harga_satuan_snapshot > 0)
);

COMMENT ON TABLE order_items IS 'Rincian item menu per pesanan (direpresentasikan sebagai embedded array `items` di Firestore).';
COMMENT ON COLUMN order_items.harga_satuan_snapshot IS 'Menyimpan harga historis saat pesanan dibuat untuk menjaga akurasi laporan pendapatan.';


-- ============================================================================
-- 5. TABEL STOCK_LOGS (Opsional / Audit Trail Perubahan Stok Logistik)
-- Mencatat riwayat keluar-masuk stok baik karena penjualan otomatis,
-- pembatalan pesanan, maupun penyesuaian stok manual oleh Kitchen/Manager.
-- ============================================================================
CREATE TABLE stock_logs (
    log_id SERIAL PRIMARY KEY,
    menu_id VARCHAR(64) NOT NULL,
    changed_by_uid VARCHAR(128) NULL, -- NULL jika dikurangi otomatis oleh pesanan QR pelanggan
    order_id VARCHAR(64) NULL,        -- Terisi jika perubahan stok berasal dari transaksi pesanan
    perubahan_qty INTEGER NOT NULL,   -- Nilai negatif (-) untuk stok keluar, positif (+) untuk masuk
    stok_akhir INTEGER NOT NULL,
    keterangan VARCHAR(100) NOT NULL, -- Contoh: 'ORDER_CHECKOUT', 'ORDER_CANCELLED', 'RESTOCK_MANAGER'
    waktu_log TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_stock_logs_menu
        FOREIGN KEY (menu_id) REFERENCES menus(menu_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_stock_logs_user
        FOREIGN KEY (changed_by_uid) REFERENCES users(uid)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_stock_logs_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_stock_logs_nonzero CHECK (perubahan_qty <> 0),
    CONSTRAINT chk_stock_logs_akhir_nonneg CHECK (stok_akhir >= 0)
);

COMMENT ON TABLE stock_logs IS 'Log audit mutasi inventaris untuk ketertelusuran rantai pasok internal.';


-- ============================================================================
-- 6. INDEX DEFINITIONS (Optimasi Kueri yang Sering Dijalankan)
-- ============================================================================

-- Index pencarian nama menu dan penyaringan kategori pada katalog Pelanggan & Kasir
CREATE INDEX idx_menus_nama ON menus (nama);
CREATE INDEX idx_menus_kategori_stok ON menus (kategori, stok);

-- Index untuk mendeteksi daftar menu yang stoknya menipis (Low Stock Alert di Dashboard Manager)
CREATE INDEX idx_menus_low_stock ON menus (stok, batas_minimum) WHERE stok <= batas_minimum;

-- Composite Index krusial untuk Kitchen Display System (KDS):
-- Menyaring berdasarkan status ('in_kitchen', 'ready') dan mengurutkan secara FIFO (waktu_pesan ASC)
CREATE INDEX idx_orders_status_fifo ON orders (status, waktu_pesan ASC);

-- Index untuk pencarian riwayat transaksi berdasarkan nomor meja & rentang waktu harian (Manager)
CREATE INDEX idx_orders_nomor_meja ON orders (nomor_meja);
CREATE INDEX idx_orders_waktu_pesan_desc ON orders (waktu_pesan DESC);

-- Index untuk mempercepat join detail item pesanan
CREATE INDEX idx_order_items_order_id ON order_items (order_id);


-- ============================================================================
-- 7. PANDUAN PEMETAAN KE CLOUD FIRESTORE (COMPOSITE INDEX & DENORMALISASI)
-- ============================================================================
/*
Pada implementasi Cloud Firestore (NoSQL), skema relasional di atas dipetakan
menjadi 3 koleksi utama dengan aturan optimasi berikut:

1. Denormalisasi `order_items` ke dalam dokumen `orders`:
   Untuk menghindari pembacaan berulang (N+1 query problem) pada layar Kitchen
   Display System, tabel `order_items` disimpan sebagai array of map `items`
   langsung di dalam dokumen `orders`.

2. Composite Index yang WAJIB dibuat pada Firebase Console (Firestore -> Indexes):
   - Collection ID : `orders`
   - Fields Indexed: `status` (Ascending) + `waktuPesan` (Ascending)
   - Tujuan        : Mendukung query antrean FIFO di layar Kitchen:
                     firestore.collection('orders')
                       .where('status', whereIn: ['in_kitchen', 'ready'])
                       .orderBy('waktuPesan', descending: false)
*/