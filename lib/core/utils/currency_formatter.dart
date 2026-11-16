import 'package:intl/intl.dart';

/// Utilitas pemformatan nilai numerik ke format mata uang Rupiah (IDR).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Mengubah angka menjadi string Rupiah, contoh: 25000 -> 'Rp 25.000'.
  static String formatRupiah(num amount) {
    return _rupiahFormatter.format(amount);
  }

  /// Alias untuk formatRupiah dengan tipe input integer.
  static String format(int amount) {
    return formatRupiah(amount);
  }

  /// Mengurai string format Rupiah kembali menjadi integer (mengembalikan null jika tidak valid).
  static int? parseRupiah(String formatted) {
    final String trimmed = formatted.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final bool isNegative = trimmed.startsWith('-');
    final String digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }
    final int? parsed = int.tryParse(digitsOnly);
    if (parsed == null) {
      return null;
    }
    return isNegative ? -parsed : parsed;
  }
}
