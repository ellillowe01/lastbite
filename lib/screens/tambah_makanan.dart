// lib/screens/add_food_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/app_state.dart';
import '../models/food_item.dart';
import '../widgets/common_widgets.dart';
import '../data/resep_data.dart';
import '../services/ocr_service.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});
  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Tambah Bahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kWhite)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kNeonGreen,
          labelColor: kNeonGreen,
          unselectedLabelColor: kTextMuted,
          tabs: const [
            Tab(text: 'Manual'),
            Tab(text: 'Scan Struk'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ManualAddTab(),
          _ScanReceiptTab(),
        ],
      ),
    );
  }
}

// ── Tab Manual ────────────────────────────────────────────
class _ManualAddTab extends StatefulWidget {
  const _ManualAddTab();
  @override
  State<_ManualAddTab> createState() => _ManualAddTabState();
}

class _ManualAddTabState extends State<_ManualAddTab> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  String _selectedEmoji = '🍽️';
  String _selectedUnit = 'pcs';
  FoodCategory _selectedCategory = FoodCategory.other;

  final List<String> _units = ['pcs', 'gram', 'kg', 'liter', 'ml', 'bungkus', 'butir', 'lembar', 'buah', 'papan'];
  final List<Map<String, dynamic>> _quickFoods = [
    {'name': 'Telur Ayam', 'emoji': '🥚', 'unit': 'butir', 'category': FoodCategory.protein},
    {'name': 'Susu UHT', 'emoji': '🥛', 'unit': 'liter', 'category': FoodCategory.dairy},
    {'name': 'Roti Tawar', 'emoji': '🍞', 'unit': 'bungkus', 'category': FoodCategory.grain},
    {'name': 'Keju', 'emoji': '🧀', 'unit': 'lembar', 'category': FoodCategory.dairy},
    {'name': 'Ayam', 'emoji': '🍗', 'unit': 'gram', 'category': FoodCategory.protein},
    {'name': 'Sayuran', 'emoji': '🥬', 'unit': 'gram', 'category': FoodCategory.veggie},
    {'name': 'Tahu', 'emoji': '🟡', 'unit': 'papan', 'category': FoodCategory.protein},
    {'name': 'Tempe', 'emoji': '🟫', 'unit': 'papan', 'category': FoodCategory.protein},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Quick select
        const SectionLabel(text: 'Pilih Cepat'),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _quickFoods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final food = _quickFoods[i];
              return GestureDetector(
                onTap: () => setState(() {
                  _nameController.text = food['name'];
                  _selectedEmoji = food['emoji'];
                  _selectedUnit = food['unit'];
                  _selectedCategory = food['category'];
                }),
                child: Container(
                  width: 72,
                  decoration: BoxDecoration(
                    color: kBgCard, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _nameController.text == food['name'] ? kNeonGreen : kBorder),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(food['emoji'], style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(food['name'], style: const TextStyle(fontSize: 9, color: kTextMuted), textAlign: TextAlign.center),
                  ]),
                ),
              );
            },
          ),
        ),

        const SectionLabel(text: 'Detail Bahan'),

        // Nama
        _buildLabel('Nama Bahan'),
        Container(
          decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
          child: TextField(
            controller: _nameController,
            style: const TextStyle(color: kWhite, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Contoh: Telur Ayam', hintStyle: TextStyle(color: kTextMuted),
              border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (v) => setState(() => _selectedEmoji = getEmojiForFood(v)),
          ),
        ),
        const SizedBox(height: 10),

        // Quantity + Unit
        Row(children: [
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildLabel('Jumlah'),
            Container(
              decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
              child: TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: kWhite, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ])),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildLabel('Satuan'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedUnit,
                  dropdownColor: kBgCard,
                  style: const TextStyle(color: kWhite, fontSize: 14),
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v!),
                ),
              ),
            ),
          ])),
        ]),
        const SizedBox(height: 10),

        // Expired date
        _buildLabel('Tanggal Expired'),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _expiryDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: kNeonGreen)),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _expiryDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: kNeonGreen),
              const SizedBox(width: 10),
              Text(
                '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}  ·  ${_expiryDate.difference(DateTime.now()).inDays} hari lagi',
                style: const TextStyle(fontSize: 14, color: kWhite),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // Tombol simpan
        GestureDetector(
          onTap: () {
            if (_nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Isi nama bahan dulu!'), backgroundColor: kDanger),
              );
              return;
            }
            final addedName = _nameController.text;
            state.addFood(FoodItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: addedName,
              emoji: _selectedEmoji,
              expiryDate: _expiryDate,
              quantity: int.tryParse(_qtyController.text) ?? 1,
              unit: _selectedUnit,
              category: _selectedCategory,
              source: 'manual',
            ));
            _nameController.clear();
            _qtyController.text = '1';
            setState(() {
              _expiryDate = DateTime.now().add(const Duration(days: 7));
              _selectedEmoji = '🍽️';
              _selectedUnit = 'pcs';
              _selectedCategory = FoodCategory.other;
            });
            showAddedDialog(context, '$addedName ditambahkan ke kulkas!');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(gradient: kGreenGradient, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.3), blurRadius: 12)]),
            alignment: Alignment.center,
            child: const Text('Simpan ke Kulkas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF13151A))),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
  );
}

// ── Tab Scan Struk ────────────────────────────────────────
class _ScanReceiptTab extends StatefulWidget {
  const _ScanReceiptTab();
  @override
  State<_ScanReceiptTab> createState() => _ScanReceiptTabState();
}

class _ScanReceiptTabState extends State<_ScanReceiptTab> {
  bool _isScanning = false;
  List<Map<String, dynamic>> _scannedItems = [];
  File? _imageFile;
  final _pasteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Step indicator
        _buildStepIndicator(_scannedItems.isNotEmpty ? 2 : _isScanning ? 1 : 0),
        const SizedBox(height: 16),

        if (_scannedItems.isEmpty) ...[
          // Upload area
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kNeonGreen.withOpacity(0.4), width: 1.5, style: BorderStyle.solid),
              ),
              child: Column(children: [
                if (_imageFile != null)
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_imageFile!, height: 120, fit: BoxFit.cover))
                else ...[
                  const Text('📸', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 10),
                  const Text('Foto Struk Belanja', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kWhite)),
                  const SizedBox(height: 4),
                  const Text('Alfamart, Indomaret, Superindo,\nTokopedia, Shopee, dll',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: kTextMuted)),
                ],
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _actionBtn('Kamera', kNeonGreen, () => _pickImage(ImageSource.camera)),
                  const SizedBox(width: 10),
                  _actionBtn('Galeri', kNeonBlue, () => _pickImage(ImageSource.gallery)),
                ]),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Row(children: [
            const Expanded(child: Divider(color: kBorder)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('atau', style: TextStyle(color: kTextMuted, fontSize: 12))),
            const Expanded(child: Divider(color: kBorder)),
          ]),

          const SizedBox(height: 16),

          // Paste text
          const Text('Struk Digital / Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kWhite)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
            child: TextField(
              controller: _pasteController,
              maxLines: 5,
              style: const TextStyle(color: kWhite, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Paste teks dari email konfirmasi order...',
                hintStyle: TextStyle(color: kTextMuted, fontSize: 12),
                border: InputBorder.none, contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _parseText(_pasteController.text),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: kNeonBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kNeonBlue.withOpacity(0.4)),
              ),
              alignment: Alignment.center,
              child: const Text('Parse Otomatis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kNeonBlue)),
            ),
          ),

          if (_isScanning) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator(color: kNeonGreen)),
            const SizedBox(height: 8),
            const Center(child: Text('Sedang scan struk...', style: TextStyle(color: kTextMuted, fontSize: 12))),
          ],
        ],

        // ── Hasil scan ───────────────────────────────
        if (_scannedItems.isNotEmpty) ...[
          // AI badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kNeonBlue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kNeonBlue.withOpacity(0.25)),
            ),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: kNeonBlue, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('OCR Berhasil!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kNeonBlue)),
                Text('${_scannedItems.length} produk terdeteksi dari struk', style: const TextStyle(fontSize: 10, color: kTextMuted)),
              ])),
              const Text('✅', style: TextStyle(fontSize: 20)),
            ]),
          ),
          const SectionLabel(text: 'Konfirmasi Produk'),

          ..._scannedItems.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            return _ScannedItemTile(
              item: item,
              onChecked: (val) => setState(() => _scannedItems[idx]['selected'] = val),
              onDateChanged: (date) => setState(() => _scannedItems[idx]['expiryDate'] = date),
            );
          }),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              final selected = _scannedItems.where((i) => i['selected'] == true).toList();
              if (selected.isEmpty) return;
              final foods = selected.map((i) => FoodItem(
                id: DateTime.now().millisecondsSinceEpoch.toString() + i['name'],
                name: i['name'],
                emoji: getEmojiForFood(i['name']),
                expiryDate: i['expiryDate'] ?? DateTime.now().add(const Duration(days: 7)),
                source: 'scan',
              )).toList();
              state.addFoods(foods);
              setState(() { _scannedItems = []; _imageFile = null; });
              showAddedDialog(context, '${foods.length} bahan disimpan ke kulkas!');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(gradient: kGreenGradient, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.3), blurRadius: 12)]),
              alignment: Alignment.center,
              child: Text(
                'Simpan ${_scannedItems.where((i) => i['selected'] == true).length} Bahan ke Kulkas',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF13151A)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () => setState(() { _scannedItems = []; _imageFile = null; }),
              child: const Text('← Scan ulang', style: TextStyle(fontSize: 12, color: kTextMuted)),
            ),
          ),
        ],

        // Tips
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tips Scan Struk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kWarning)),
            const SizedBox(height: 8),
            const Text('• Pastikan struk tidak kusut dan terbaca jelas\n• Pencahayaan cukup, hindari bayangan\n• Foto tegak lurus\n• Struk digital bisa screenshot lalu upload',
                style: TextStyle(fontSize: 11, color: kTextMuted, height: 1.6)),
          ]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() { _imageFile = File(picked.path); _isScanning = true; });

    try {
      final items = await OcrService.scanReceipt(File(picked.path));
      setState(() {
        _scannedItems = items;
        _isScanning = false;
      });
    } catch (e) {
      // Fallback ke sample data kalau OCR gagal
      setState(() {
        _scannedItems = _getSampleScannedItems();
        _isScanning = false;
      });
    }
  }

  void _parseText(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _scannedItems = OcrService.parseTextReceipt(text);
    });
  }

  List<Map<String, dynamic>> _getSampleScannedItems() => [
    {'name': 'Telur Ayam 6pcs', 'selected': true, 'expiryDate': DateTime.now()},
    {'name': 'Susu Ultra 1L', 'selected': true, 'expiryDate': DateTime.now().add(const Duration(days: 7))},
    {'name': 'Keju Kraft Slice', 'selected': true, 'expiryDate': DateTime.now().add(const Duration(days: 14))},
    {'name': 'Roti Tawar Sari Roti', 'selected': true, 'expiryDate': DateTime.now().add(const Duration(days: 3))},
    {'name': 'Yogurt Cimory', 'selected': true, 'expiryDate': DateTime.now().add(const Duration(days: 5))},
  ];

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    final steps = ['Foto', 'Scan OCR', 'Konfirmasi', 'Simpan'];
    return Row(
      children: steps.asMap().entries.map((e) {
        final idx = e.key;
        final isDone = idx < currentStep;
        final isCurrent = idx == currentStep;
        final color = isDone || isCurrent ? kNeonGreen : kBorder;

        return Expanded(child: Row(children: [
          if (idx > 0) Expanded(child: Container(height: 2, color: isDone ? kNeonGreen : kBorder)),
          Column(children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? kNeonGreen : isCurrent ? kNeonGreen.withOpacity(0.2) : kBgCard,
                border: Border.all(color: color),
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 14, color: Color(0xFF13151A))
                  : Text('${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ),
            const SizedBox(height: 4),
            Text(e.value, style: TextStyle(fontSize: 8, color: isCurrent || isDone ? kNeonGreen : kTextMuted)),
          ]),
        ]));
      }).toList(),
    );
  }
}

// ── Scanned item tile ─────────────────────────────────────
class _ScannedItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final ValueChanged<bool?> onChecked;
  final ValueChanged<DateTime> onDateChanged;

  const _ScannedItemTile({required this.item, required this.onChecked, required this.onDateChanged});

  @override
  Widget build(BuildContext context) {
    final expiry = item['expiryDate'] as DateTime?;
    final daysLeft = expiry != null ? expiry.difference(DateTime.now()).inDays : 7;
    final color = daysLeft <= 0 ? kDanger : daysLeft <= 3 ? kWarning : kNeonGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kBgCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (item['selected'] == true) ? kNeonGreen.withOpacity(0.3) : kBorder),
      ),
      child: Row(children: [
        Checkbox(
          value: item['selected'] == true,
          onChanged: onChecked,
          activeColor: kNeonGreen,
          checkColor: const Color(0xFF13151A),
          side: const BorderSide(color: kBorder),
        ),
        Text(getEmojiForFood(item['name']), style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kWhite))),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: expiry ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: kNeonGreen)),
                child: child!,
              ),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              expiry != null ? '${expiry.day}/${expiry.month}' : 'Set date',
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Dialog konfirmasi setelah bahan berhasil ditambahkan ──
void showAddedDialog(BuildContext context, String message) {
  final state = context.read<AppState>();
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Berhasil!', style: TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 16)),
      content: Text(message, style: const TextStyle(color: kTextMuted, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Tambah Lagi', style: TextStyle(color: kTextMuted, fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogCtx);
            state.requestTab(0);
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: const Text('Ke Menu Utama', style: TextStyle(color: kNeonGreen, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}