// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../models/food_item.dart';

// ─── LastBite Color Palette ───────────────────────────────
const Color kBg         = Color(0xFF1E2128);  // background utama
const Color kBgCard     = Color(0xFF2E3440);  // card
const Color kBgSurface  = Color(0xFF3D4451);  // surface/input
const Color kBgLight    = Color(0xFFF8F9FA);  // putih bersih
const Color kNeonGreen  = Color(0xFF00FF88);  // hijau neon (fresh/safe)
const Color kNeonBlue   = Color(0xFF4FC3F7);  // biru langit
const Color kWarning    = Color(0xFFFFB800);  // kuning (warning)
const Color kDanger     = Color(0xFFFF4757);  // merah (danger)
const Color kWhite      = Color(0xFFECEFF4);  // teks putih
const Color kTextMuted  = Color(0xFF6B7280);  // teks muted
const Color kBorder     = Color(0xFF3D4451);  // border

// Gradient utama
const LinearGradient kGreenGradient = LinearGradient(
  colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);

const LinearGradient kBlueGradient = LinearGradient(
  colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);

// ─── Expiry status warna ─────────────────────────────────
Color expiryColor(ExpiryStatus status) {
  switch (status) {
    case ExpiryStatus.expired:  return kDanger;
    case ExpiryStatus.critical: return kDanger;
    case ExpiryStatus.warning:  return kWarning;
    case ExpiryStatus.safe:     return kNeonGreen;
  }
}

// ─── Section Label ────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionLabel({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(children: [
        Container(width: 3, height: 14,
          decoration: BoxDecoration(
            gradient: kGreenGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text.toUpperCase(), style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 1.2, color: color ?? kNeonGreen,
        )),
      ]),
    );
  }
}

// ─── Food Item Card ───────────────────────────────────────
class FoodItemCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FoodItemCard({super.key, required this.food, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final col = food.statusColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col.withOpacity(0.3), width: 0.8),
          boxShadow: [BoxShadow(color: col.withOpacity(0.06), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Emoji besar
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: col.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: col.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(food.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(food.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kWhite)),
                const SizedBox(height: 2),
                Text('${food.quantity} ${food.unit}  ·  ${food.source == 'scan' ? 'Scan' : 'Manual'}',
                    style: const TextStyle(fontSize: 11, color: kTextMuted)),
              ])),
              // Days left badge
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: col.withOpacity(0.4)),
                  ),
                  child: Text(food.statusLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: col)),
                ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(Icons.delete_outline_rounded, size: 16, color: kTextMuted),
                    ),
                  ),
              ]),
            ]),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: food.expiryProgress,
                minHeight: 4,
                backgroundColor: kBgSurface,
                valueColor: AlwaysStoppedAnimation<Color>(col),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recipe Card ──────────────────────────────────────────
class RecipeCard extends StatelessWidget {
  final dynamic recipe; // Recipe model
  final int matchCount;
  final VoidCallback? onTap;
  final bool isHighlight;

  const RecipeCard({
    super.key, required this.recipe,
    this.matchCount = 0, this.onTap, this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlight ? kNeonGreen.withOpacity(0.4) : kBorder,
            width: isHighlight ? 1.2 : 0.8,
          ),
          boxShadow: isHighlight ? [BoxShadow(color: kNeonGreen.withOpacity(0.1), blurRadius: 12)] : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header image area
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: isHighlight
                  ? const LinearGradient(colors: [Color(0xFF0A2E1A), Color(0xFF0A1A2E)])
                  : const LinearGradient(colors: [Color(0xFF2E3440), Color(0xFF1E2128)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            alignment: Alignment.center,
            child: Text(recipe.emoji, style: const TextStyle(fontSize: 40)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(recipe.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kWhite))),
                if (isHighlight)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: kNeonGreen, borderRadius: BorderRadius.circular(8)),
                    child: const Text('#1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF13151A))),
                  ),
              ]),
              const SizedBox(height: 4),
              Text('${recipe.cookTimeMinutes} mnt  ·  ${recipe.calories} kkal  ·  ${recipe.difficulty}',
                  style: const TextStyle(fontSize: 10, color: kTextMuted)),
              const SizedBox(height: 8),
              Wrap(spacing: 4, runSpacing: 4, children: [
                if (matchCount > 0)
                  _tag('$matchCount bahan ada', kNeonGreen),
                ...recipe.tags.take(2).map<Widget>((t) => _tag(t, kNeonBlue)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3), width: 0.5),
    ),
    child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
  );
}

// ─── Stat Card ────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData? icon;

  const StatCard({super.key, required this.value, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) Icon(icon, size: 18, color: color),
        if (icon != null) const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: kTextMuted)),
      ]),
    );
  }
}

// ─── Mood Chip ────────────────────────────────────────────
class MoodChip extends StatelessWidget {
  final String label, emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodChip({super.key, required this.label, required this.emoji, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? kGreenGradient : null,
          color: isSelected ? null : kBgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : kBorder),
          boxShadow: isSelected ? [BoxShadow(color: kNeonGreen.withOpacity(0.3), blurRadius: 8)] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF13151A) : kTextMuted,
          )),
        ]),
      ),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────
class SearchBar2 extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const SearchBar2({super.key, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 0.8),
      ),
      child: Row(children: [
        const Icon(Icons.search_rounded, size: 18, color: kTextMuted),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: kWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kTextMuted, fontSize: 13),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        )),
      ]),
    );
  }
}