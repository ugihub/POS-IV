import '../constants/app_constants.dart';

/// Kumpulan validator terpusat untuk TextFormField dan validasi QR meja.
class Validators {
  Validators._();

  static final RegExp _tableQrRegex = RegExp(AppConstants.tableNumberPattern);
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Validasi input string wajib isi (tidak boleh null atau hanya spasi).
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validasi nama menu (wajib diisi dan minimal 3 karakter setelah trim).
  static String? validateMenuName(String? value) {
    final String? requiredError = validateRequired(
      value,
      fieldName: 'Nama menu',
    );
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().length < 3) {
      return 'Nama menu minimal 3 karakter';
    }
    return null;
  }

  /// Validasi harga satuan menu (wajib bilangan bulat > 0).
  static String? validatePrice(String? value) {
    final String? requiredError = validateRequired(value, fieldName: 'Harga');
    if (requiredError != null) {
      return requiredError;
    }
    final String cleaned = value!.trim().replaceAll(RegExp(r'[Rp\s.]'), '');
    final int? parsed = int.tryParse(cleaned);
    if (parsed == null) {
      return 'Harga harus berupa angka valid';
    }
    if (parsed <= 0) {
      return 'Harga harus lebih besar dari 0';
    }
    return null;
  }

  /// Validasi stok menu (wajib bilangan bulat >= 0).
  static String? validateStock(String? value) {
    final String? requiredError = validateRequired(value, fieldName: 'Stok');
    if (requiredError != null) {
      return requiredError;
    }
    final int? parsed = int.tryParse(value!.trim());
    if (parsed == null) {
      return 'Stok harus berupa bilangan bulat valid';
    }
    if (parsed < 0) {
      return 'Stok tidak boleh bernilai negatif';
    }
    return null;
  }

  /// Validasi batas minimum stok peringatan (wajib bilangan bulat >= 0).
  static String? validateMinStock(String? value) {
    final String? requiredError = validateRequired(
      value,
      fieldName: 'Batas minimum stok',
    );
    if (requiredError != null) {
      return requiredError;
    }
    final int? parsed = int.tryParse(value!.trim());
    if (parsed == null) {
      return 'Batas minimum stok harus berupa bilangan bulat valid';
    }
    if (parsed < 0) {
      return 'Batas minimum stok tidak boleh bernilai negatif';
    }
    return null;
  }

  /// Validasi format string QR kode meja sesuai pola ^MEJA-\d{2}$.
  static String? validateTableQr(String? value) {
    final String? requiredError = validateRequired(
      value,
      fieldName: 'Nomor meja',
    );
    if (requiredError != null) {
      return requiredError;
    }
    if (!_tableQrRegex.hasMatch(value!.trim())) {
      return 'Format QR meja tidak valid (contoh: MEJA-01 hingga MEJA-99)';
    }
    return null;
  }

  /// Pengecekan boolean apakah string QR meja memenuhi pola ^MEJA-\d{2}$.
  static bool isValidTableQr(String? value) {
    if (value == null) {
      return false;
    }
    return _tableQrRegex.hasMatch(value.trim());
  }

  /// Validasi format email untuk form login staf.
  static String? validateEmail(String? value) {
    final String? requiredError = validateRequired(value, fieldName: 'Email');
    if (requiredError != null) {
      return requiredError;
    }
    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validasi kata sandi untuk form login staf (minimal 6 karakter).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }
}
