// lib/screens/recipe_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/resep.dart';
import '../widgets/common_widgets.dart';
import 'cookpad_search_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  bool _showExpiring = true; // true = dari bahan hampir expired, false = semua

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final recipes = _showExpiring ? state.getRecipesForExpiring() : state.allRecipesCombined;

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
                  child: const Text('Darurat Masak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const Text('Resep dari bahan yang ada', style: TextStyle(fontSize: 12, color: kTextMuted)),
                const SizedBox(height: 14),

                // Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                  child: Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: () => setState(() => _showExpiring = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: _showExpiring ? kGreenGradient : null,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text('Hampir Expired', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: _showExpiring ? const Color(0xFF13151A) : kTextMuted,
                        )),
                      ),
                    )),
                    Expanded(child: GestureDetector(
                      onTap: () => setState(() => _showExpiring = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: !_showExpiring ? kGreenGradient : null,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text('Semua Resep', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: !_showExpiring ? const Color(0xFF13151A) : kTextMuted,
                        )),
                      ),
                    )),
                  ]),
                ),
                const SizedBox(height: 12),

                // Search bar → Cookpad (in-app)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CookpadSearchScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: kBgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF6F0F).withOpacity(0.3), width: 0.8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.search_rounded, size: 18, color: kTextMuted),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Cari resep lain di Cookpad...', style: TextStyle(fontSize: 13, color: kTextMuted))),
                      Icon(Icons.travel_explore_rounded, size: 16, color: const Color(0xFFFF6F0F)),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── Recipe list ──────────────────────────────
            Expanded(
              child: recipes.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🍽️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('Belum ada resep yang cocok', style: TextStyle(color: kTextMuted)),
                const SizedBox(height: 8),
                const Text('Tambah bahan ke kulkas dulu!', style: TextStyle(color: kTextMuted, fontSize: 12)),
              ]))
                  : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: recipes.length,
                itemBuilder: (context, i) {
                  final recipe = recipes[i];
                  final availableNames = state.foods.map((f) => f.name).toList();
                  return RecipeCard(
                    recipe: recipe,
                    matchCount: recipe.matchCount(availableNames),
                    isHighlight: i == 0,
                    onTap: () => _showRecipeDetail(context, recipe),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetail(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Text(recipe.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(recipe.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kWhite)),
                Text('${recipe.cookTimeMinutes} mnt  ·  ${recipe.calories} kkal  ·  ${recipe.difficulty}',
                    style: const TextStyle(fontSize: 11, color: kTextMuted)),
              ])),
            ]),
            const SizedBox(height: 16),

            const Text('Bahan-bahan:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kWhite)),
            const SizedBox(height: 8),
            ...recipe.ingredients.map((ing) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 10, top: 2),
                    decoration: const BoxDecoration(color: kNeonGreen, shape: BoxShape.circle)),
                Text(ing, style: const TextStyle(fontSize: 13, color: kWhite)),
              ]),
            )),
            const SizedBox(height: 16),

            const Text('Cara Memasak:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kWhite)),
            const SizedBox(height: 8),
            ...recipe.steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 24, height: 24, margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(gradient: kGreenGradient, borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.center,
                  child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF13151A))),
                ),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: kWhite, height: 1.4))),
              ]),
            )),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CookpadSearchScreen(initialQuery: recipe.name)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6F0F).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF6F0F).withOpacity(0.4)),
                ),
                alignment: Alignment.center,
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Cari Resep Lain di Cookpad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFF6F0F))),
                  SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFFFF6F0F)),
                ]),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}