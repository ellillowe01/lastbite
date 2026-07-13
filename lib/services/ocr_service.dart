// lib/services/ocr_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  // Scan gambar struk pakai ML Kit
  static Future<List<Map<String, dynamic>>> scanReceipt(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    return _parseReceiptText(recognizedText.text);
  }

  // Parse teks yang di-paste manual
  static List<Map<String, dynamic>> parseTextReceipt(String text) {
    return _parseReceiptText(text);
  }

  // Core parser — ekstrak nama produk dari teks struk
  static List<Map<String, dynamic>> _parseReceiptText(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final items = <Map<String, dynamic>>[];

    // Keywords yang biasanya ada di struk tapi bukan produk
    final skipKeywords = [
      'total', 'subtotal', 'tunai', 'kembalian', 'ppn', 'diskon',
      'terima kasih', 'kasir', 'alfamart', 'indomaret', 'superindo',
      'tanggal', 'jam', 'no.', 'telp', 'npwp', 'pt.', 'cv.',
      'tokopedia', 'shopee', 'rp', 'qty', 'harga', 'pesanan',
    ];

    // Keywords makanan/minuman yang kemungkinan besar ada di struk
    final foodKeywords = [
      'telur', 'susu', 'roti', 'keju', 'ayam', 'daging', 'ikan',
      'sayur', 'wortel', 'tomat', 'kentang', 'bawang', 'mie', 'pasta',
      'nasi', 'beras', 'tahu', 'tempe', 'yogurt', 'mentega', 'minyak',
      'tepung', 'gula', 'garam', 'kecap', 'saos', 'saus', 'minuman',
      'jus', 'air', 'teh', 'kopi', 'coklat', 'snack', 'biskuit',
      'ultra', 'indomie', 'sari roti', 'cimory', 'kraft', 'frisian',
    ];

    for (final line in lines) {
      final lower = line.toLowerCase();

      // Skip baris yang berisi keyword non-produk
      if (skipKeywords.any((k) => lower.contains(k))) continue;

      // Skip baris yang terlalu pendek atau hanya angka
      if (line.length < 4) continue;
      if (RegExp(r'^[\d\s\.,\-]+$').hasMatch(line)) continue;

      // Prioritaskan baris yang mengandung keyword makanan
      final isFoodItem = foodKeywords.any((k) => lower.contains(k));

      // Bersihkan nama produk dari angka harga di belakang
      String cleanName = line.replaceAll(RegExp(r'\s+\d[\d\.,]+\s*$'), '').trim();
      cleanName = cleanName.replaceAll(RegExp(r'\s+x\d+\s*$'), '').trim();

      if (cleanName.length >= 4 && (isFoodItem || _looksLikeProduct(cleanName))) {
        items.add({
          'name': _capitalizeWords(cleanName),
          'selected': true,
          'expiryDate': _guessExpiryDate(cleanName),
        });
      }

      if (items.length >= 10) break; // Max 10 item
    }

    // Kalau tidak dapat hasil, return sample
    if (items.isEmpty) return _getSampleItems();
    return items;
  }

  // Cek apakah baris terlihat seperti nama produk
  static bool _looksLikeProduct(String line) {
    // Produk biasanya punya huruf + mungkin angka (ukuran)
    return RegExp(r'[a-zA-Z]{3,}').hasMatch(line) && line.length > 5;
  }

  // Tebak tanggal expired berdasarkan jenis produk
  static DateTime _guessExpiryDate(String name) {
    final lower = name.toLowerCase();
    final now = DateTime.now();

    if (lower.contains('telur')) return now;
    if (lower.contains('susu') || lower.contains('yogurt')) return now.add(const Duration(days: 7));
    if (lower.contains('roti')) return now.add(const Duration(days: 3));
    if (lower.contains('keju')) return now.add(const Duration(days: 14));
    if (lower.contains('ayam') || lower.contains('daging')) return now.add(const Duration(days: 2));
    if (lower.contains('sayur') || lower.contains('wortel') || lower.contains('tomat')) return now.add(const Duration(days: 5));
    if (lower.contains('tahu') || lower.contains('tempe')) return now.add(const Duration(days: 3));
    if (lower.contains('mie') || lower.contains('pasta')) return now.add(const Duration(days: 365));
    if (lower.contains('beras') || lower.contains('tepung')) return now.add(const Duration(days: 180));
    return now.add(const Duration(days: 30));
  }

  static String _capitalizeWords(String text) {
    return text.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  static List<Map<String, dynamic>> _getSampleItems() {
    final now = DateTime.now();
    return [
      {'name': 'Telur Ayam 6pcs',      'selected': true, 'expiryDate': now},
      {'name': 'Susu Ultra 1L',         'selected': true, 'expiryDate': now.add(const Duration(days: 7))},
      {'name': 'Keju Kraft Slice',      'selected': true, 'expiryDate': now.add(const Duration(days: 14))},
      {'name': 'Roti Tawar Sari Roti',  'selected': true, 'expiryDate': now.add(const Duration(days: 3))},
      {'name': 'Yogurt Cimory',         'selected': true, 'expiryDate': now.add(const Duration(days: 5))},
    ];
  }
}