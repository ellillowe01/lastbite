// lib/models/food_item.dart
import 'package:flutter/material.dart';

enum FoodCategory { protein, dairy, veggie, fruit, grain, snack, beverage, other }

class FoodItem {
  final String id;
  String name;
  String emoji;
  DateTime expiryDate;
  DateTime addedDate;
  int quantity;
  String unit; // pcs, gram, liter, dll
  FoodCategory category;
  String source; // manual, scan, online
  String? calendarEventId; // id event di kalender native HP, kalau sudah disinkron

  FoodItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.expiryDate,
    DateTime? addedDate,
    this.quantity = 1,
    this.unit = 'pcs',
    this.category = FoodCategory.other,
    this.source = 'manual',
    this.calendarEventId,
  }) : addedDate = addedDate ?? DateTime.now();

  // Hari tersisa hingga expired
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  // Status expired
  ExpiryStatus get status {
    if (daysLeft < 0) return ExpiryStatus.expired;
    if (daysLeft == 0) return ExpiryStatus.critical;
    if (daysLeft <= 3) return ExpiryStatus.warning;
    return ExpiryStatus.safe;
  }

  // Warna berdasarkan status
  Color get statusColor {
    switch (status) {
      case ExpiryStatus.expired:  return const Color(0xFFFF4757);
      case ExpiryStatus.critical: return const Color(0xFFFF4757);
      case ExpiryStatus.warning:  return const Color(0xFFFFB800);
      case ExpiryStatus.safe:     return const Color(0xFF00FF88);
    }
  }

  // Label status
  String get statusLabel {
    switch (status) {
      case ExpiryStatus.expired:  return 'Expired!';
      case ExpiryStatus.critical: return 'Hari ini!';
      case ExpiryStatus.warning:  return '$daysLeft hari lagi';
      case ExpiryStatus.safe:     return '$daysLeft hari lagi';
    }
  }

  // Progress bar value (0.0 - 1.0)
  double get expiryProgress {
    final totalDays = expiryDate.difference(addedDate).inDays;
    if (totalDays <= 0) return 0.0;
    final remaining = daysLeft / totalDays;
    return remaining.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'emoji': emoji,
    'expiryDate': expiryDate.toIso8601String(),
    'addedDate': addedDate.toIso8601String(),
    'quantity': quantity, 'unit': unit,
    'category': category.index, 'source': source,
    'calendarEventId': calendarEventId,
  };

  factory FoodItem.fromMap(Map<String, dynamic> map) => FoodItem(
    id: map['id'], name: map['name'], emoji: map['emoji'],
    expiryDate: DateTime.parse(map['expiryDate']),
    addedDate: DateTime.parse(map['addedDate']),
    quantity: map['quantity'], unit: map['unit'],
    category: FoodCategory.values[map['category']],
    source: map['source'],
    calendarEventId: map['calendarEventId'],
  );
}

enum ExpiryStatus { expired, critical, warning, safe }