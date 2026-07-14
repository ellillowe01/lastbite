// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/account_sheet.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final critical = state.criticalFoods;
    final warning = state.warningFoods;
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Selamat pagi' : now.hour < 17 ? 'Selamat siang' : 'Selamat malam';

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(greeting, style: const TextStyle(fontSize: 12, color: kTextMuted)),
                      ShaderMask(
                        shaderCallback: (b) => kGreenGradient.createShader(b),
                        child: Text(state.userName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ]),
                    GestureDetector(
                      onTap: () => showAccountSheet(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: kBgCard,
                          border: Border.all(color: kNeonGreen.withOpacity(0.4)),
                          boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.2), blurRadius: 10)],
                          image: state.userPhotoUrl != null
                              ? DecorationImage(image: NetworkImage(state.userPhotoUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: state.userPhotoUrl == null
                            ? const Icon(Icons.person_outline_rounded, size: 20, color: kNeonGreen)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Alert Banner ─────────────────────────────
            if (critical.isNotEmpty)
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => state.requestTab(1),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kDanger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kDanger.withOpacity(0.4)),
                      boxShadow: [BoxShadow(color: kDanger.withOpacity(0.1), blurRadius: 12)],
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: kDanger.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: const Text('🔥', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${critical.length} bahan mau expired ${critical.any((f) => f.daysLeft == 0) ? 'hari ini' : 'segera'}!',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDanger)),
                        const SizedBox(height: 2),
                        Text(critical.map((f) => f.name).join(', '),
                            style: const TextStyle(fontSize: 11, color: kTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kDanger),
                    ]),
                  ),
                ),
              ),

            if (warning.isNotEmpty && critical.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kWarning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kWarning.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Text('⚠️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${warning.length} bahan akan expired dalam 1-3 hari',
                        style: const TextStyle(fontSize: 12, color: kWarning, fontWeight: FontWeight.w600))),
                  ]),
                ),
              ),

            // ── Stat Cards ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  Expanded(child: StatCard(
                    value: '${state.totalFoods}',
                    label: 'Bahan di Kulkas',
                    color: kNeonGreen,
                    icon: Icons.kitchen_outlined,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(
                    value: '${state.expiringCount}',
                    label: 'Segera Expired',
                    color: state.expiringCount > 0 ? kDanger : kNeonGreen,
                    icon: Icons.timer_outlined,
                  )),
                ]),
              ),
            ),

            // ── Segera Dimasak ───────────────────────────
            if (critical.isNotEmpty || warning.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SectionLabel(text: 'Segera Dimasak'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final items = [...critical, ...warning];
                      final food = items[i];
                      return FoodItemCard(
                        food: food,
                        onTap: () {},
                        onDelete: () => state.removeFood(food.id),
                      );
                    },
                    childCount: (critical.length + warning.length).clamp(0, 3),
                  ),
                ),
              ),
            ],

            // ── Quick Actions ─────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionLabel(text: 'Aksi Cepat'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => state.requestTab(2),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: kGreenGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.3), blurRadius: 12)],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('🍳', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 8),
                          const Text('Darurat\nMasak', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF13151A))),
                          const SizedBox(height: 4),
                          Text('${state.getRecipesForExpiring().length} resep tersedia',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF1A3D2A))),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => state.requestTab(1),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kNeonBlue.withOpacity(0.3)),
                          boxShadow: [BoxShadow(color: kNeonBlue.withOpacity(0.1), blurRadius: 10)],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('🧊', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 8),
                          const Text('Lihat\nKulkas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kWhite)),
                          const SizedBox(height: 4),
                          Text('${state.totalFoods} bahan tersimpan',
                              style: const TextStyle(fontSize: 10, color: kTextMuted)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Semua bahan (preview) ─────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionLabel(text: 'Isi Kulkas'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final food = state.sortedByExpiry[i];
                    return FoodItemCard(food: food, onDelete: () => state.removeFood(food.id));
                  },
                  childCount: state.sortedByExpiry.length.clamp(0, 5),
                ),
              ),
            ),

            if (state.totalFoods > 5)
              SliverToBoxAdapter(
                child: Center(
                  child: GestureDetector(
                    onTap: () => state.requestTab(1),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: kBgCard, borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorder),
                      ),
                      child: Text('Lihat semua ${state.totalFoods} bahan →',
                          style: const TextStyle(fontSize: 12, color: kTextMuted)),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}