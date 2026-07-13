// lib/data/recipes_data.dart
import '../models/resep.dart';

final List<Recipe> allRecipes = [
  // ── SARAPAN ──────────────────────────────────────────
  Recipe(
    id: 'r001', name: 'Telur Dadar Keju', emoji: '🍳',
    ingredients: ['telur', 'keju', 'garam', 'minyak'],
    steps: ['Kocok telur + garam', 'Panaskan minyak', 'Tuang telur, tabur keju', 'Lipat dan sajikan'],
    cookTimeMinutes: 10, calories: 250, difficulty: 'Mudah',
    tags: ['sarapan', 'cepat', 'bergizi'],
    mealTime: 'pagi', moods: ['lapar', 'ngantuk', 'semangat'],
  ),
  Recipe(
    id: 'r002', name: 'French Toast Susu', emoji: '🍞',
    ingredients: ['roti', 'telur', 'susu', 'gula', 'mentega'],
    steps: ['Campur telur + susu + gula', 'Celup roti', 'Goreng dengan mentega hingga keemasan', 'Sajikan dengan madu'],
    cookTimeMinutes: 15, calories: 320, difficulty: 'Mudah',
    tags: ['sarapan', 'manis', 'mengenyangkan'],
    mealTime: 'pagi', moods: ['happy', 'santai'],
  ),
  Recipe(
    id: 'r003', name: 'Oatmeal Pisang', emoji: '🥣',
    ingredients: ['oatmeal', 'susu', 'pisang', 'madu'],
    steps: ['Masak oatmeal dengan susu', 'Iris pisang', 'Tambahkan madu', 'Sajikan hangat'],
    cookTimeMinutes: 8, calories: 280, difficulty: 'Mudah',
    tags: ['sarapan', 'sehat', 'diet'],
    mealTime: 'pagi', moods: ['sehat', 'semangat'],
  ),

  // ── MAKAN SIANG ───────────────────────────────────────
  Recipe(
    id: 'r004', name: 'Mie Goreng Telur Spesial', emoji: '🍜',
    ingredients: ['mie', 'telur', 'sawi', 'bawang', 'kecap', 'minyak'],
    steps: ['Rebus mie, tiriskan', 'Tumis bawang hingga harum', 'Masukkan telur, orak-arik', 'Tambah sawi + kecap', 'Masukkan mie, aduk rata'],
    cookTimeMinutes: 15, calories: 450, difficulty: 'Mudah',
    tags: ['makan siang', 'mengenyangkan', 'favorit'],
    mealTime: 'siang', moods: ['lapar', 'cape'],
  ),
  Recipe(
    id: 'r005', name: 'Nasi Goreng Keju', emoji: '🍚',
    ingredients: ['nasi', 'telur', 'keju', 'bawang', 'kecap', 'minyak'],
    steps: ['Tumis bawang', 'Masukkan nasi, aduk', 'Tambah telur orak-arik', 'Tabur keju parut', 'Sajikan dengan kerupuk'],
    cookTimeMinutes: 20, calories: 520, difficulty: 'Mudah',
    tags: ['makan siang', 'mengenyangkan', 'klasik'],
    mealTime: 'siang', moods: ['lapar', 'pengen enak'],
  ),
  Recipe(
    id: 'r006', name: 'Sup Telur Sayur', emoji: '🥣',
    ingredients: ['telur', 'wortel', 'kentang', 'bawang', 'garam'],
    steps: ['Rebus air + bawang', 'Masukkan wortel + kentang potong', 'Pecahkan telur langsung ke kuah', 'Bumbui dengan garam + merica'],
    cookTimeMinutes: 25, calories: 180, difficulty: 'Mudah',
    tags: ['makan siang', 'sehat', 'hangat'],
    mealTime: 'siang', moods: ['sakit', 'galau', 'dingin'],
  ),
  Recipe(
    id: 'r007', name: 'Sandwich Keju Telur', emoji: '🥪',
    ingredients: ['roti', 'telur', 'keju', 'mentega', 'sayur selada'],
    steps: ['Goreng telur mata sapi', 'Olesi roti dengan mentega', 'Susun telur + keju + selada', 'Tutup dengan roti, potong diagonal'],
    cookTimeMinutes: 12, calories: 380, difficulty: 'Mudah',
    tags: ['makan siang', 'praktis', 'cepat'],
    mealTime: 'siang', moods: ['sibuk', 'praktis'],
  ),

  // ── MAKAN MALAM ───────────────────────────────────────
  Recipe(
    id: 'r008', name: 'Telur Balado Pedas', emoji: '🌶️',
    ingredients: ['telur', 'cabai', 'bawang merah', 'bawang putih', 'tomat', 'minyak'],
    steps: ['Rebus telur, kupas', 'Goreng sebentar', 'Haluskan bumbu balado', 'Tumis bumbu + telur', 'Sajikan dengan nasi'],
    cookTimeMinutes: 30, calories: 280, difficulty: 'Sedang',
    tags: ['makan malam', 'pedas', 'lauk'],
    mealTime: 'malam', moods: ['lapar', 'pengen pedas'],
  ),
  Recipe(
    id: 'r009', name: 'Tumis Sayur Tahu', emoji: '🥬',
    ingredients: ['tahu', 'sawi', 'wortel', 'bawang putih', 'kecap', 'minyak'],
    steps: ['Potong tahu + sayur', 'Tumis bawang putih', 'Masukkan tahu, goreng', 'Tambah sayur + kecap', 'Aduk rata, sajikan'],
    cookTimeMinutes: 20, calories: 220, difficulty: 'Mudah',
    tags: ['makan malam', 'sehat', 'vegetarian'],
    mealTime: 'malam', moods: ['sehat', 'diet', 'santai'],
  ),
  Recipe(
    id: 'r010', name: 'Puding Susu Coklat', emoji: '🍮',
    ingredients: ['susu', 'coklat bubuk', 'gula', 'agar-agar'],
    steps: ['Campur susu + coklat + gula', 'Tambah agar-agar', 'Masak hingga mendidih', 'Tuang ke cetakan', 'Dinginkan 2 jam'],
    cookTimeMinutes: 20, calories: 180, difficulty: 'Mudah',
    tags: ['dessert', 'manis', 'dingin'],
    mealTime: 'semua', moods: ['happy', 'pengen manis'],
  ),

  // ── SNACK / CAMILAN ───────────────────────────────────
  Recipe(
    id: 'r011', name: 'Roti Bakar Keju Susu', emoji: '🧇',
    ingredients: ['roti', 'keju', 'susu kental manis', 'mentega'],
    steps: ['Olesi roti dengan mentega', 'Bakar di teflon', 'Tambah keju + susu kental', 'Lipat, sajikan hangat'],
    cookTimeMinutes: 8, calories: 290, difficulty: 'Mudah',
    tags: ['snack', 'manis', 'cepat'],
    mealTime: 'semua', moods: ['ngantuk', 'pengen ngemil'],
  ),
  Recipe(
    id: 'r012', name: 'Salad Telur Mayo', emoji: '🥗',
    ingredients: ['telur', 'mayones', 'selada', 'tomat', 'garam'],
    steps: ['Rebus telur, iris', 'Potong selada + tomat', 'Campur dengan mayones', 'Bumbui garam + merica', 'Sajikan dingin'],
    cookTimeMinutes: 15, calories: 220, difficulty: 'Mudah',
    tags: ['salad', 'sehat', 'segar'],
    mealTime: 'siang', moods: ['sehat', 'diet', 'segar'],
  ),
];

// Emoji default per kategori
const Map<String, String> categoryEmoji = {
  'telur': '🥚', 'susu': '🥛', 'keju': '🧀', 'roti': '🍞',
  'nasi': '🍚', 'mie': '🍜', 'ayam': '🍗', 'daging': '🥩',
  'ikan': '🐟', 'tahu': '🟡', 'tempe': '🟫', 'wortel': '🥕',
  'kentang': '🥔', 'tomat': '🍅', 'bawang': '🧅', 'sawi': '🥬',
  'pisang': '🍌', 'apel': '🍎', 'jeruk': '🍊', 'yogurt': '🧴',
  'mentega': '🧈', 'minyak': '🫙', 'gula': '🍬', 'garam': '🧂',
};

String getEmojiForFood(String name) {
  final lower = name.toLowerCase();
  for (final entry in categoryEmoji.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return '🍽️';
}