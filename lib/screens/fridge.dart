// lib/screens/fridge_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/food_item.dart';
import '../widgets/common_widgets.dart';
import 'tambah_makanan.dart';

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});
  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  String _filter = 'Semua';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    List<FoodItem> filtered = state.sortedByExpiry.where((f) {
      final matchSearch = f.name.toLowerCase().contains(_search.toLowerCase());
      final matchFilter = _filter == 'Semua' ||
          (_filter == 'Kritis' && (f.status == ExpiryStatus.critical || f.status == ExpiryStatus.expired)) ||
          (_filter == 'Segera' && f.status == ExpiryStatus.warning) ||
          (_filter == 'Aman' && f.status == ExpiryStatus.safe);
      return matchSearch && matchFilter;
    }).toList();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ShaderMask(
                  shaderCallback: (b) => kGreenGradient.createShader(b),
                  child: const Text('Isi Kulkas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                Text('${state.totalFoods} bahan tersimpan', style: const TextStyle(fontSize: 12, color: kTextMuted)),
              ]),
            ),

            // ── Search ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: SearchBar2(hint: 'Cari bahan makanan...', onChanged: (v) => setState(() => _search = v)),
            ),

            // ── Filter pills ─────────────────────────────
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                scrollDirection: Axis.horizontal,
                children: ['Semua', 'Kritis', 'Segera', 'Aman'].map((f) {
                  final isSelected = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isSelected ? kGreenGradient : null,
                        color: isSelected ? null : kBgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.transparent : kBorder),
                      ),
                      child: Text(f, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF13151A) : kTextMuted,
                      )),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── List ─────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🧊', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Tidak ada bahan', style: TextStyle(color: kTextMuted, fontSize: 14)),
              ]))
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: filtered.length,
                itemBuilder: (context, i) => FoodItemCard(
                  food: filtered[i],
                  onDelete: () => state.removeFood(filtered[i].id),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFoodScreen())),
        backgroundColor: kNeonGreen,
        foregroundColor: const Color(0xFF13151A),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Bahan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}