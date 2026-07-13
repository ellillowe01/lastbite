// lib/food_item.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/fridge.dart';
import 'screens/tambah_makanan.dart';
import 'screens/tambah_resep.dart';
import 'screens/resep_screen.dart';
import 'screens/recom.dart';
import 'widgets/common_widgets.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Firebase belum dikonfigurasi (lihat firebase_options.dart) — app tetap
    // jalan sepenuhnya lokal, fitur login/sinkronisasi cloud otomatis nonaktif.
  }
  await NotificationService.init();
  // Ditunggu (bukan fire-and-forget) supaya dialog izin notifikasi selesai
  // dulu sebelum AppState.syncAllReminders() minta izin kalender — dua
  // permintaan izin Android yang tabrakan bisa bikin salah satunya gagal
  // diam-diam (denied) tanpa dialog sungguhan muncul.
  await NotificationService.requestPermissions();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const LastBiteApp(),
    ),
  );
}

class LastBiteApp extends StatelessWidget {
  const LastBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LastBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(primary: kNeonGreen, surface: kBg),
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        fontFamily: 'Roboto',
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    FridgeScreen(),
    RecipeScreen(),
    RecommendationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final requested = state.requestedTab;
    if (requested != null && requested != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _currentIndex = requested);
        state.clearTabRequest();
      });
    } else if (requested != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => state.clearTabRequest());
    }

    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF13151A),
          border: const Border(top: BorderSide(color: kBorder, width: 0.5)),
          boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: kNeonGreen,
          unselectedItemColor: kTextMuted,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.kitchen_outlined),
                if (state.expiringCount > 0)
                  Positioned(top: -4, right: -4, child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(color: kDanger, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('${state.expiringCount}', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800)),
                  )),
              ]),
              activeIcon: const Icon(Icons.kitchen_rounded),
              label: 'Kulkas',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined), activeIcon: Icon(Icons.restaurant_rounded), label: 'Masak'),
            const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome_rounded), label: 'Rekom'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  // FAB "+" mengikuti tab yang aktif: di Kulkas sudah ada tombol tambah
  // sendiri, jadi disembunyikan; di Masak (Resep) mengarah ke tambah resep,
  // bukan tambah bahan kulkas.
  Widget? _buildFab(BuildContext context) {
    switch (_currentIndex) {
      case 1: // Kulkas — punya FAB extended sendiri di FridgeScreen
        return null;
      case 2: // Masak / Resep
        return FloatingActionButton(
          heroTag: 'fab-add-recipe',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRecipeScreen())),
          backgroundColor: kNeonGreen,
          foregroundColor: const Color(0xFF13151A),
          child: const Icon(Icons.add_rounded, size: 28),
        );
      case 3: // Rekomendasi — tidak ada aksi tambah yang relevan
        return null;
      default: // Home
        return FloatingActionButton(
          heroTag: 'fab-add-food',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFoodScreen())),
          backgroundColor: kNeonGreen,
          foregroundColor: const Color(0xFF13151A),
          child: const Icon(Icons.add_rounded, size: 28),
        );
    }
  }
}