// lib/screens/recommendation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_state.dart';
import '../services/ai_service.dart';
import '../widgets/common_widgets.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  static const moods = [
    {'id': 'lapar',       'label': 'Lapar Banget', 'emoji': '😋'},
    {'id': 'ngantuk',     'label': 'Ngantuk',      'emoji': '😴'},
    {'id': 'sehat',       'label': 'Mau Sehat',    'emoji': '💪'},
    {'id': 'galau',       'label': 'Galau',        'emoji': '🌧️'},
    {'id': 'happy',       'label': 'Happy',        'emoji': '🎉'},
    {'id': 'pengen pedas','label': 'Pengen Pedas', 'emoji': '🌶️'},
    {'id': 'pengen manis','label': 'Pengen Manis', 'emoji': '🍫'},
    {'id': 'diet',        'label': 'Diet',         'emoji': '🥗'},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final recommendations = state.getRecommendations();
    final mealTime = state.currentMealTime;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) => kGreenGradient.createShader(b),
              child: const Text('Mau Makan Apa?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(height: 4),
            Text('Rekomendasi personal untukmu', style: const TextStyle(fontSize: 12, color: kTextMuted)),
            const SizedBox(height: 14),

            // ── Rekomendasi AI ────────────────────────────
            const _AiRecommendationCard(),

            // ── Time auto detect ─────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kNeonGreen.withOpacity(0.3)),
              ),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: kNeonGreen, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: kNeonGreen, blurRadius: 4)])),
                const SizedBox(width: 10),
                Text(mealTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kNeonGreen)),
                const SizedBox(width: 8),
                Text('· ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB',
                    style: const TextStyle(fontSize: 12, color: kTextMuted)),
                const Spacer(),
                const Icon(Icons.access_time_rounded, size: 14, color: kTextMuted),
              ]),
            ),

            // ── Mood selector ────────────────────────────
            const SectionLabel(text: 'Mood Kamu Sekarang?'),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: moods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final mood = moods[i];
                  return MoodChip(
                    label: mood['label']!,
                    emoji: mood['emoji']!,
                    isSelected: state.selectedMood == mood['id'],
                    onTap: () => state.setMood(mood['id']!),
                  );
                },
              ),
            ),

            // ── Toggle bahan kulkas ───────────────────────
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => state.setUseAvailableIngredients(!state.useAvailableIngredients),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: state.useAvailableIngredients ? kNeonGreen.withOpacity(0.4) : kBorder),
                ),
                child: Row(children: [
                  const Text('🧊', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Dari Bahan Kulkas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kWhite)),
                    Text('${state.totalFoods} bahan tersedia', style: const TextStyle(fontSize: 11, color: kTextMuted)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: state.useAvailableIngredients ? kNeonGreen.withOpacity(0.15) : kBgSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: state.useAvailableIngredients ? kNeonGreen.withOpacity(0.5) : kBorder),
                    ),
                    child: Text(
                      state.useAvailableIngredients ? 'ON' : 'OFF',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: state.useAvailableIngredients ? kNeonGreen : kTextMuted),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Recommendations ───────────────────────────
            const SectionLabel(text: 'Rekomendasi Untukmu'),

            if (recommendations.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
                child: const Column(children: [
                  Text('🍽️', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 10),
                  Text('Tidak ada rekomendasi', style: TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Coba ganti mood atau tambah bahan dulu', style: TextStyle(color: kTextMuted, fontSize: 12)),
                ]),
              )
            else ...[
              // Top pick
              _TopPickCard(recipe: recommendations.first, state: state),
              const SizedBox(height: 10),

              // Sisanya
              ...recommendations.skip(1).take(4).map((recipe) {
                final availableNames = state.foods.map((f) => f.name).toList();
                return RecipeCard(
                  recipe: recipe,
                  matchCount: recipe.matchCount(availableNames),
                  onTap: () => state.requestTab(2),
                );
              }),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Top Pick Card ─────────────────────────────────────────
class _TopPickCard extends StatelessWidget {
  final dynamic recipe;
  final AppState state;
  const _TopPickCard({required this.recipe, required this.state});

  @override
  Widget build(BuildContext context) {
    final availableNames = state.foods.map((f) => f.name).toList();
    final match = recipe.matchCount(availableNames);

    return GestureDetector(
      onTap: () => state.requestTab(2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A2E1A), Color(0xFF0A1A2E)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kNeonGreen.withOpacity(0.4), width: 1.2),
          boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.1), blurRadius: 16)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(recipe.emoji, style: const TextStyle(fontSize: 36)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kNeonGreen, borderRadius: BorderRadius.circular(8)),
              child: const Text('#1 PICK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF13151A))),
            ),
          ]),
          const SizedBox(height: 10),
          Text(recipe.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kWhite)),
          const SizedBox(height: 4),
          Text('Cocok untuk ${state.currentMealTime.toLowerCase()} · Mood: ${state.selectedMood}',
              style: const TextStyle(fontSize: 11, color: kTextMuted)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (match > 0) _tag('$match bahan ada di kulkas', kNeonGreen),
            _tag('${recipe.cookTimeMinutes} menit', kNeonBlue),
            _tag('${recipe.calories} kkal', kWarning),
            ...recipe.tags.take(1).map<Widget>((t) => _tag(t, kTextMuted)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kNeonGreen.withOpacity(0.2)),
            ),
            child: Text('Bahan: ${recipe.ingredients.take(4).join(', ')}...',
                style: const TextStyle(fontSize: 11, color: kTextMuted, height: 1.4)),
          ),
        ]),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3), width: 0.5),
    ),
    child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );
}

// ── Kartu Rekomendasi AI (Gemini) ──────────────────────────
class _AiRecommendationCard extends StatefulWidget {
  const _AiRecommendationCard();
  @override
  State<_AiRecommendationCard> createState() => _AiRecommendationCardState();
}

class _AiRecommendationCardState extends State<_AiRecommendationCard> {
  bool _loading = false;
  String? _result;
  String? _error;
  final _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _ask(BuildContext context) async {
    final state = context.read<AppState>();
    final apiKey = state.geminiApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      _showApiKeyDialog(context);
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final ingredients = state.foods.map((f) => f.name).toList();
      final text = await AiService.getRecommendation(
        apiKey: apiKey,
        ingredients: ingredients,
        mood: state.selectedMood,
        mealTime: state.currentMealTime,
        customQuestion: _questionController.text,
      );
      if (!mounted) return;
      setState(() => _result = text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal minta rekomendasi AI: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController(text: context.read<AppState>().geminiApiKey ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Gemini API Key', style: TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Masukkan API key Gemini kamu. Key hanya disimpan di perangkat ini.',
              style: TextStyle(color: kTextMuted, fontSize: 12)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            style: const TextStyle(color: kWhite, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'AIzaSy...', hintStyle: const TextStyle(color: kTextMuted),
              filled: true, fillColor: kBgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('https://aistudio.google.com/apikey'), mode: LaunchMode.externalApplication),
            child: const Text('Belum punya key? Buat gratis di Google AI Studio →',
                style: TextStyle(color: kNeonBlue, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: kTextMuted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().setGeminiApiKey(controller.text.trim());
              Navigator.pop(dialogCtx);
            },
            child: const Text('Simpan', style: TextStyle(color: kNeonGreen, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasKey = (state.geminiApiKey ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF0A1A2E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kNeonBlue.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🤖', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          const Expanded(child: Text('Bingung Mau Makan Apa?', style: TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 14))),
          GestureDetector(
            onTap: () => _showApiKeyDialog(context),
            child: const Icon(Icons.settings_outlined, size: 18, color: kTextMuted),
          ),
        ]),
        const SizedBox(height: 4),
        const Text('Biar AI yang kasih rekomendasi, sesuai bahan & mood kamu — atau ketik permintaanmu sendiri.',
            style: TextStyle(fontSize: 11, color: kTextMuted)),
        const SizedBox(height: 12),

        if (hasKey)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _questionController,
              style: const TextStyle(color: kWhite, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Contoh: resep tanpa telur dong... (opsional)',
                hintStyle: const TextStyle(color: kTextMuted, fontSize: 12),
                filled: true, fillColor: Colors.black.withOpacity(0.2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: _loading ? null : (_) => _ask(context),
            ),
          ),

        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: kNeonBlue, strokeWidth: 2.5))),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 12)),
          )
        else if (_result != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: _buildResultText(_result!),
          ),

        GestureDetector(
          onTap: _loading ? null : () => _ask(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kNeonBlue, Color(0xFF7C4DFF)]),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              hasKey ? 'Tanya AI Sekarang' : 'Atur API Key Dulu',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
      ]),
    );
  }

  // Render teks jawaban AI dengan link (http/https) yang bisa diklik.
  static final _urlRegex = RegExp(r'(https?://[^\s]+)');
  static final _trailingPunctRegex = RegExp(r'[.,;:!?)\]]+$');

  Widget _buildResultText(String text) {
    final spans = <InlineSpan>[];
    int start = 0;
    for (final match in _urlRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      var url = match.group(0)!;
      var trailing = '';
      final trailMatch = _trailingPunctRegex.firstMatch(url);
      if (trailMatch != null) {
        trailing = url.substring(trailMatch.start);
        url = url.substring(0, trailMatch.start);
      }
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(color: kNeonBlue, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
        recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ));
      if (trailing.isNotEmpty) spans.add(TextSpan(text: trailing));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return Text.rich(
      TextSpan(style: const TextStyle(color: kWhite, fontSize: 13, height: 1.4), children: spans),
    );
  }
}