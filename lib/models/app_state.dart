// lib/models/app_state.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'food_item.dart';
import 'resep.dart';
import '../data/resep_data.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/calendar_service.dart';

class AppState extends ChangeNotifier {
  List<FoodItem> _foods = [];
  List<Recipe> _customRecipes = [];
  String _selectedMood = 'lapar';
  bool _useAvailableIngredients = true;
  int? _requestedTab;
  String? _geminiApiKey;
  String? _uid;
  String? _userPhotoUrl;
  String? _userName;
  StreamSubscription<User?>? _authSub;

  List<FoodItem> get foods => _foods;
  List<Recipe> get customRecipes => _customRecipes;
  String get selectedMood => _selectedMood;
  bool get useAvailableIngredients => _useAvailableIngredients;
  int? get requestedTab => _requestedTab;
  String? get geminiApiKey => _geminiApiKey;
  bool get isLoggedIn => _uid != null;
  String? get userPhotoUrl => _userPhotoUrl;
  String get userName => _userName ?? 'LastBite';

  // Semua resep: buatan sendiri + resep bawaan
  List<Recipe> get allRecipesCombined => [..._customRecipes, ...allRecipes];

  AppState() {
    _loadFromPrefs().then((_) => syncAllReminders());
    _loadRecipesFromPrefs();
    _loadApiKeyFromPrefs();
    _bindAuth();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── Akun & sinkronisasi cloud (Firestore) ────────────
  // Kalau Firebase belum dikonfigurasi (lihat firebase_options.dart), stream
  // ini akan gagal jadi tidak pernah subscribe — app tetap jalan lokal saja.
  void _bindAuth() {
    try {
      _authSub = AuthService.authStateChanges.listen(_onAuthChanged, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _onAuthChanged(User? user) async {
    _uid = user?.uid;
    _userPhotoUrl = user?.photoURL;
    _userName = user?.displayName ?? user?.email?.split('@').first;
    notifyListeners();
    if (user != null) await _syncOnSignIn(user.uid);
  }

  // Login di akun ini → tarik data dari cloud kalau ada. Kalau belum ada
  // dokumen cloud sama sekali, cek dulu apakah data lokal yang lagi nyangkut
  // ini memang milik akun ini (login pertama kali dari mode lokal) atau sisa
  // dari akun LAIN yang tadinya login di perangkat ini (ganti akun) — supaya
  // data akun lama tidak ikut ke-upload jadi data akun baru.
  Future<void> _syncOnSignIn(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUid = prefs.getString('lastSyncedUid');

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        final oldFoods = _foods;
        final foodsJson = (data['foods'] as List?) ?? [];
        final recipesJson = (data['customRecipes'] as List?) ?? [];
        _foods = foodsJson.map((m) => FoodItem.fromMap(Map<String, dynamic>.from(m as Map))).toList();
        _customRecipes = recipesJson.map((m) => Recipe.fromMap(Map<String, dynamic>.from(m as Map))).toList();
        await _saveToPrefs();
        await _saveRecipesToPrefs();
        notifyListeners();
        await _clearStaleReminders(oldFoods, _foods);
        await syncAllReminders();
      } else if (lastUid == null || lastUid == uid) {
        // Belum pernah ada akun lain tersinkron di perangkat ini, atau ini
        // memang akun yang sama seperti sebelumnya → data lokal sah milik
        // akun ini, unggah sebagai salinan cloud pertamanya.
        await _pushToCloud();
      } else {
        // Data lokal ini sisa dari akun berbeda (lastUid != uid) — reset
        // supaya akun baru mulai kosong, bukan mewarisi data akun lama.
        // Notifikasi & event kalender milik item akun lama itu juga harus
        // dibersihkan di sini — kalau tidak, event kalendernya nyangkut
        // permanen di kalender HP walau item-nya sudah tidak ada di app.
        final oldFoods = _foods;
        _foods = [];
        _customRecipes = [];
        await _saveToPrefs();
        await _saveRecipesToPrefs();
        notifyListeners();
        await _pushToCloud();
        await _clearStaleReminders(oldFoods, _foods);
      }

      await prefs.setString('lastSyncedUid', uid);
    } catch (_) {
      // Offline atau Firebase belum siap — tetap pakai data lokal.
    }
  }

  // Batalkan notifikasi & hapus event kalender untuk item yang tidak lagi
  // ada di daftar terbaru (mis. setelah ganti akun) — supaya tidak ada event
  // kalender "sampah" yang nyangkut permanen di kalender HP.
  Future<void> _clearStaleReminders(List<FoodItem> oldFoods, List<FoodItem> newFoods) async {
    final newIds = newFoods.map((f) => f.id).toSet();
    for (final food in oldFoods) {
      if (newIds.contains(food.id)) continue;
      try {
        await NotificationService.cancelForFood(food.id);
        await CalendarService.deleteEventForFood(food);
      } catch (_) {}
    }
  }

  Future<void> _pushToCloud() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'foods': _foods.map((f) => f.toMap()).toList(),
        'customRecipes': _customRecipes.map((r) => r.toMap()).toList(),
      });
    } catch (_) {
      // Gagal sinkron (offline, dll) — data lokal tetap aman, dicoba lagi di aksi berikutnya.
    }
  }

  // Minta MainNavigation pindah ke tab tertentu (mis. balik ke Beranda)
  void requestTab(int index) {
    _requestedTab = index;
    notifyListeners();
  }

  void clearTabRequest() {
    _requestedTab = null;
  }

  // ── Filter & sort ────────────────────────────────────
  List<FoodItem> get criticalFoods =>
      _foods.where((f) => f.status == ExpiryStatus.critical || f.status == ExpiryStatus.expired).toList()
        ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  List<FoodItem> get warningFoods =>
      _foods.where((f) => f.status == ExpiryStatus.warning).toList()
        ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  List<FoodItem> get safeFoods =>
      _foods.where((f) => f.status == ExpiryStatus.safe).toList()
        ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  List<FoodItem> get sortedByExpiry =>
      List<FoodItem>.from(_foods)..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  int get totalFoods => _foods.length;
  int get expiringCount => criticalFoods.length + warningFoods.length;

  // ── CRUD ─────────────────────────────────────────────
  void addFood(FoodItem food) {
    _foods.add(food);
    _saveToPrefs();
    _pushToCloud();
    notifyListeners();
    _scheduleReminders(food);
  }

  void addFoods(List<FoodItem> foods) {
    _foods.addAll(foods);
    _saveToPrefs();
    _pushToCloud();
    notifyListeners();
    for (final food in foods) {
      _scheduleReminders(food);
    }
  }

  void removeFood(String id) {
    FoodItem? food;
    for (final f in _foods) {
      if (f.id == id) { food = f; break; }
    }
    _foods.removeWhere((f) => f.id == id);
    _saveToPrefs();
    _pushToCloud();
    notifyListeners();
    if (food != null) {
      NotificationService.cancelForFood(id);
      CalendarService.deleteEventForFood(food);
    }
  }

  void updateFood(FoodItem food) {
    final idx = _foods.indexWhere((f) => f.id == food.id);
    if (idx != -1) { _foods[idx] = food; _saveToPrefs(); _pushToCloud(); notifyListeners(); _scheduleReminders(food); }
  }

  // ── Notifikasi & sinkronisasi kalender ───────────────
  Future<void> _scheduleReminders(FoodItem food) async {
    try {
      await NotificationService.scheduleForFood(food);
      final eventId = await CalendarService.upsertEventForFood(food);
      if (eventId != null && eventId != food.calendarEventId) {
        food.calendarEventId = eventId;
        await _saveToPrefs();
        // addFood/updateFood sudah push ke cloud lebih dulu, sebelum
        // calendarEventId ini didapat (proses kalender jalan async belakangan)
        // — kalau tidak di-push ulang di sini, cloud akan selalu punya versi
        // basi tanpa calendarEventId, dan sinkron cloud berikutnya (mis. saat
        // app dibuka lagi) akan menimpa balik data lokal yang sudah benar.
        await _pushToCloud();
      }
    } catch (_) {}
  }

  // Dipanggil sekali saat app dibuka supaya item yang sudah tersimpan
  // sebelum fitur ini ada (atau lolos ter-schedule, mis. sesudah restart HP)
  // ikut ke-cover.
  Future<void> syncAllReminders() async {
    for (final food in _foods) {
      if (food.status == ExpiryStatus.expired) continue;
      await _scheduleReminders(food);
    }
  }

  void setMood(String mood) { _selectedMood = mood; notifyListeners(); }
  void setUseAvailableIngredients(bool val) { _useAvailableIngredients = val; notifyListeners(); }

  // ── AI (Gemini) API key — tersimpan lokal di perangkat ──
  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiApiKey', key);
    notifyListeners();
  }

  Future<void> _loadApiKeyFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('geminiApiKey');
      if (key != null && key.isNotEmpty) {
        _geminiApiKey = key;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Custom recipes ───────────────────────────────────
  void addRecipe(Recipe recipe) {
    _customRecipes.add(recipe);
    _saveRecipesToPrefs();
    _pushToCloud();
    notifyListeners();
  }

  void removeRecipe(String id) {
    _customRecipes.removeWhere((r) => r.id == id);
    _saveRecipesToPrefs();
    _pushToCloud();
    notifyListeners();
  }

  // ── Recipe matching ──────────────────────────────────
  List<Recipe> getRecipesForExpiring() {
    final expiringNames = criticalFoods.map((f) => f.name).toList()
      ..addAll(warningFoods.map((f) => f.name));
    if (expiringNames.isEmpty) return allRecipesCombined.take(5).toList();

    final scored = allRecipesCombined.map((r) {
      final score = r.matchCount(expiringNames);
      return {'recipe': r, 'score': score};
    }).where((e) => (e['score'] as int) > 0).toList()
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return scored.map((e) => e['recipe'] as Recipe).toList();
  }

  List<Recipe> getRecommendations() {
    final now = DateTime.now();
    final hour = now.hour;
    String mealTime;
    if (hour < 10) mealTime = 'pagi';
    else if (hour < 15) mealTime = 'siang';
    else mealTime = 'malam';

    final availableNames = _foods.map((f) => f.name).toList();

    List<Recipe> filter({required bool matchTime, required bool matchMood}) {
      return allRecipesCombined.where((r) {
        final timeMatch = !matchTime || r.mealTime == mealTime || r.mealTime == 'semua';
        final moodMatch = !matchMood || r.moods.isEmpty || r.moods.contains(_selectedMood);
        final ingredientMatch = !_useAvailableIngredients || r.matchCount(availableNames) > 0;
        return timeMatch && moodMatch && ingredientMatch;
      }).toList();
    }

    // Data resep bawaan kecil & tag mood-nya jarang, jadi filter ketat
    // (waktu + mood + bahan) gampang banget kosong. Longgarkan bertahap —
    // mood dulu, baru waktu makan — sebelum benar-benar nyerah ke "kosong".
    // Toggle bahan kulkas tetap dihormati di semua tahap karena itu pilihan
    // eksplisit user, bukan default ambient seperti mood/waktu.
    var result = filter(matchTime: true, matchMood: true);
    if (result.isEmpty) result = filter(matchTime: true, matchMood: false);
    if (result.isEmpty) result = filter(matchTime: false, matchMood: false);
    if (result.isEmpty) {
      result = allRecipesCombined.where((r) => !_useAvailableIngredients || r.matchCount(availableNames) > 0).toList();
    }

    result.sort((a, b) => b.matchCount(availableNames).compareTo(a.matchCount(availableNames)));
    return result;
  }

  String get currentMealTime {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'Sarapan';
    if (hour < 15) return 'Makan Siang';
    if (hour < 18) return 'Snack Sore';
    return 'Makan Malam';
  }

  // ── Persistence ──────────────────────────────────────
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _foods.map((f) => f.toMap()).toList();
    await prefs.setString('foods', jsonEncode(json));
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('foods');
      if (str != null) {
        final list = jsonDecode(str) as List;
        _foods = list.map((m) => FoodItem.fromMap(m as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveRecipesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _customRecipes.map((r) => r.toMap()).toList();
    await prefs.setString('customRecipes', jsonEncode(json));
  }

  Future<void> _loadRecipesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('customRecipes');
      if (str != null) {
        final list = jsonDecode(str) as List;
        _customRecipes = list.map((m) => Recipe.fromMap(m as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }
}