import 'app_constants.dart';

/// Kumpulan pola ekspresi reguler (RegExp) untuk validasi QR meja dan pencarian.
class RegexPatterns {
  RegexPatterns._();

  static const String tableQrPattern = AppConstants.tableNumberPattern;

  static RegExp get tableQrRegExp => RegExp(tableQrPattern);

  /// Membangun RegExp pencarian case-insensitive secara aman.
  /// Jika pengguna mengetik karakter regex mentah yang belum lengkap (misal '['),
  /// fallback ke pencocokan literal agar UI tidak melempar FormatException.
  static RegExp buildSearchRegExp(String query) {
    final String trimmed = query.trim();
    try {
      return RegExp(trimmed, caseSensitive: false);
    } on FormatException {
      return RegExp(RegExp.escape(trimmed), caseSensitive: false);
    }
  }
}
