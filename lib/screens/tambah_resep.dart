// lib/screens/tambah_resep.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/resep.dart';
import '../widgets/common_widgets.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});
  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _nameController = TextEditingController();
  final _cookTimeController = TextEditingController(text: '15');
  final _caloriesController = TextEditingController(text: '300');
  final _servingsController = TextEditingController(text: '1');
  final _ingredientController = TextEditingController();
  final _stepController = TextEditingController();

  String _selectedEmoji = '🍽️';
  String _difficulty = 'Mudah';
  String _mealTime = 'semua';
  final List<String> _ingredients = [];
  final List<String> _steps = [];

  final List<String> _emojiOptions = ['🍽️', '🍳', '🍜', '🍚', '🥪', '🥣', '🍲', '🥘', '🍛', '🥗'];
  final List<String> _difficulties = ['Mudah', 'Sedang', 'Susah'];
  final List<Map<String, String>> _mealTimes = [
    {'id': 'semua', 'label': 'Semua'},
    {'id': 'pagi', 'label': 'Pagi'},
    {'id': 'siang', 'label': 'Siang'},
    {'id': 'malam', 'label': 'Malam'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _cookTimeController.dispose();
    _caloriesController.dispose();
    _servingsController.dispose();
    _ingredientController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _ingredients.add(text);
      _ingredientController.clear();
    });
  }

  void _addStep() {
    final text = _stepController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _steps.add(text);
      _stepController.clear();
    });
  }

  void _resetForm() {
    _nameController.clear();
    _cookTimeController.text = '15';
    _caloriesController.text = '300';
    _servingsController.text = '1';
    _ingredientController.clear();
    _stepController.clear();
    setState(() {
      _selectedEmoji = '🍽️';
      _difficulty = 'Mudah';
      _mealTime = 'semua';
      _ingredients.clear();
      _steps.clear();
    });
  }

  void _save(BuildContext context) {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama resep dulu!'), backgroundColor: kDanger),
      );
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 bahan!'), backgroundColor: kDanger),
      );
      return;
    }
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 langkah memasak!'), backgroundColor: kDanger),
      );
      return;
    }

    final state = context.read<AppState>();
    final recipeName = _nameController.text.trim();
    state.addRecipe(Recipe(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: recipeName,
      emoji: _selectedEmoji,
      ingredients: List<String>.from(_ingredients),
      steps: List<String>.from(_steps),
      cookTimeMinutes: int.tryParse(_cookTimeController.text) ?? 15,
      calories: int.tryParse(_caloriesController.text) ?? 300,
      servings: int.tryParse(_servingsController.text) ?? 1,
      difficulty: _difficulty,
      mealTime: _mealTime,
    ));

    _showSuccessDialog(context, state, recipeName);
  }

  void _showSuccessDialog(BuildContext context, AppState state, String recipeName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resep Tersimpan!', style: TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('"$recipeName" berhasil ditambahkan ke daftar resep.',
            style: const TextStyle(color: kTextMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _resetForm();
            },
            child: const Text('Tambah Lagi', style: TextStyle(color: kTextMuted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              state.requestTab(2); // tetap di tab Masak
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Ke Menu Utama', style: TextStyle(color: kNeonGreen, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: kWhite, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tambah Resep', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kWhite)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionLabel(text: 'Emoji Resep'),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emojiOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final emoji = _emojiOptions[i];
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      color: kBgCard, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? kNeonGreen : kBorder, width: isSelected ? 2 : 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ),

          const SectionLabel(text: 'Detail Resep'),
          _buildLabel('Nama Resep'),
          Container(
            decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Contoh: Nasi Goreng Spesial', hintStyle: TextStyle(color: kTextMuted),
                border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildLabel('Waktu (menit)'),
              _numberField(_cookTimeController),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildLabel('Kalori'),
              _numberField(_caloriesController),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildLabel('Porsi'),
              _numberField(_servingsController),
            ])),
          ]),
          const SizedBox(height: 10),

          _buildLabel('Tingkat Kesulitan'),
          Row(children: _difficulties.map((d) {
            final isSelected = d == _difficulty;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _difficulty = d),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? kGreenGradient : null,
                  color: isSelected ? null : kBgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? Colors.transparent : kBorder),
                ),
                alignment: Alignment.center,
                child: Text(d, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF13151A) : kTextMuted,
                )),
              ),
            ));
          }).toList()),
          const SizedBox(height: 10),

          _buildLabel('Waktu Makan'),
          Row(children: _mealTimes.map((m) {
            final isSelected = m['id'] == _mealTime;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _mealTime = m['id']!),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? kGreenGradient : null,
                  color: isSelected ? null : kBgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? Colors.transparent : kBorder),
                ),
                alignment: Alignment.center,
                child: Text(m['label']!, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF13151A) : kTextMuted,
                )),
              ),
            ));
          }).toList()),

          const SectionLabel(text: 'Bahan-bahan'),
          Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
              child: TextField(
                controller: _ingredientController,
                style: const TextStyle(color: kWhite, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Contoh: telur', hintStyle: TextStyle(color: kTextMuted),
                  border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _addIngredient(),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addIngredient,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(gradient: kGreenGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_rounded, color: Color(0xFF13151A)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (_ingredients.isEmpty)
            const Text('Belum ada bahan ditambahkan', style: TextStyle(color: kTextMuted, fontSize: 12))
          else
            Wrap(spacing: 8, runSpacing: 8, children: _ingredients.asMap().entries.map((e) {
              return Chip(
                label: Text(e.value, style: const TextStyle(color: kWhite, fontSize: 12)),
                backgroundColor: kBgCard,
                side: const BorderSide(color: kBorder),
                deleteIcon: const Icon(Icons.close_rounded, size: 16, color: kTextMuted),
                onDeleted: () => setState(() => _ingredients.removeAt(e.key)),
              );
            }).toList()),

          const SectionLabel(text: 'Cara Memasak'),
          Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
              child: TextField(
                controller: _stepController,
                style: const TextStyle(color: kWhite, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Kocok telur + garam', hintStyle: TextStyle(color: kTextMuted),
                  border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _addStep(),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addStep,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(gradient: kGreenGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_rounded, color: Color(0xFF13151A)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (_steps.isEmpty)
            const Text('Belum ada langkah ditambahkan', style: TextStyle(color: kTextMuted, fontSize: 12))
          else
            ..._steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 22, height: 22, margin: const EdgeInsets.only(right: 10, top: 2),
                  decoration: BoxDecoration(gradient: kGreenGradient, borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.center,
                  child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF13151A))),
                ),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: kWhite))),
                GestureDetector(
                  onTap: () => setState(() => _steps.removeAt(e.key)),
                  child: const Icon(Icons.close_rounded, size: 16, color: kTextMuted),
                ),
              ]),
            )),

          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _save(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(gradient: kGreenGradient, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.3), blurRadius: 12)]),
              alignment: Alignment.center,
              child: const Text('Simpan Resep', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF13151A))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller) => Container(
    decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: kWhite, fontSize: 14),
      decoration: const InputDecoration(
        border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
  );

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
  );
}
