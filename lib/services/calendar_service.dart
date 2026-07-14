// lib/services/calendar_service.dart
import 'dart:io';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/food_item.dart';

// Sinkron otomatis (silent, tanpa konfirmasi manual per item) ke kalender
// native HP, sebagai cadangan kalau notifikasi in-app tidak muncul. Semua
// method gagal diam-diam kalau izin ditolak atau plugin error — fitur ini
// tidak boleh sampai bikin app crash / data lokal gagal tersimpan.
//
// Catatan: bergantung pada `tz.local` yang sudah di-set oleh
// NotificationService.init() — di AppState, scheduleForFood selalu
// dipanggil sebelum upsertEventForFood.
class CalendarService {
  static final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  static const _calendarIdPrefsKey = 'lastbite_calendar_id';
  static const _calendarName = 'LastBite';

  static Future<bool> requestPermissions() async {
    try {
      var result = await _plugin.hasPermissions();
      if (result.isSuccess && result.data == true) return true;
      result = await _plugin.requestPermissions();
      return result.isSuccess && result.data == true;
    } catch (_) {
      return false;
    }
  }

  // Semua id kalender bernama "LastBite" yang ada di HP — bisa lebih dari
  // satu kalau app pernah ke-reinstall total (mis. gara-gara storage penuh)
  // dan cache id kalendernya ikut hilang, sehingga kode sempat bikin
  // kalender baru padahal yang lama masih ada. Dipakai supaya proses hapus
  // event tetap bisa nemu event lama walau dibuat di kalender "LastBite"
  // yang berbeda dari yang aktif sekarang.
  static Future<List<String>> _allLastBiteCalendarIds() async {
    try {
      final calendarsResult = await _plugin.retrieveCalendars();
      final calendars = calendarsResult.data ?? [];
      return calendars.where((c) => c.name == _calendarName).map((c) => c.id! as String).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<String?> _getOrCreateCalendarId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_calendarIdPrefsKey);

      final calendarsResult = await _plugin.retrieveCalendars();
      final calendars = calendarsResult.data ?? [];

      if (cached != null && calendars.any((c) => c.id == cached)) return cached;

      // Kalau ada lebih dari satu kalender "LastBite" (sisa reinstall lama),
      // pakai yang id-nya paling kecil/paling lama — konsisten di semua
      // device supaya tidak nambah kalender baru lagi setiap kali cache
      // hilang.
      final existing = calendars.where((c) => c.name == _calendarName && c.isReadOnly != true).toList()
        ..sort((a, b) => a.id!.compareTo(b.id!));
      if (existing.isNotEmpty) {
        await prefs.setString(_calendarIdPrefsKey, existing.first.id!);
        return existing.first.id;
      }

      if (Platform.isAndroid) {
        final createResult = await _plugin.createCalendar(
          _calendarName,
          calendarColor: Colors.green,
          localAccountName: _calendarName,
        );
        if (createResult.isSuccess && createResult.data != null) {
          await prefs.setString(_calendarIdPrefsKey, createResult.data!);
          return createResult.data;
        }
      }

      // iOS tidak bisa bikin kalender baru lewat plugin ini — fallback ke
      // kalender writable pertama (prioritas yang default).
      final writable = calendars.where((c) => c.isReadOnly != true).toList()
        ..sort((a, b) => (b.isDefault == true ? 1 : 0) - (a.isDefault == true ? 1 : 0));
      if (writable.isEmpty) return null;
      await prefs.setString(_calendarIdPrefsKey, writable.first.id!);
      return writable.first.id;
    } catch (_) {
      return null;
    }
  }

  // Update-in-place (mengirim `eventId` yang sudah ada ke createOrUpdateEvent)
  // memicu NullPointerException native di plugin device_calendar pada
  // sejumlah device/Android version. Supaya sinkron tetap reliable, event
  // lama dihapus dulu (best-effort, abaikan kalau gagal) lalu selalu bikin
  // event baru — jalur create murni ini yang stabil.
  static Future<String?> upsertEventForFood(FoodItem food) async {
    if (!await requestPermissions()) return null;
    final calendarId = await _getOrCreateCalendarId();
    if (calendarId == null) return null;

    if (food.calendarEventId != null) {
      await _deleteEventFromAllCalendars(food.calendarEventId!);
    }

    final expiry = food.expiryDate;
    final start = tz.TZDateTime(tz.local, expiry.year, expiry.month, expiry.day, 9, 0);
    final end = start.add(const Duration(hours: 1));

    final event = Event(
      calendarId,
      title: '${food.emoji} ${food.name} Expired',
      description: '${food.quantity} ${food.unit} ${food.name} akan expired hari ini. (LastBite)',
      start: start,
      end: end,
      reminders: [Reminder(minutes: 0), Reminder(minutes: 1440)],
    );

    try {
      final result = await _plugin.createOrUpdateEvent(event);
      if (result != null && result.isSuccess) return result.data;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteEventForFood(FoodItem food) async {
    final eventId = food.calendarEventId;
    if (eventId == null) return;
    if (!await requestPermissions()) return;
    await _deleteEventFromAllCalendars(eventId);
  }

  // Coba hapus id event ini dari SETIAP kalender "LastBite" yang ada (bukan
  // cuma yang lagi aktif) — event lama bisa nyangkut di kalender "LastBite"
  // lain kalau cache id kalendernya sempat hilang (mis. app di-reinstall
  // total). Kebanyakan percobaan akan no-op karena event-nya memang tidak
  // ada di situ; yang penting yang benar-benar menyimpannya ikut kena.
  static Future<void> _deleteEventFromAllCalendars(String eventId) async {
    final ids = await _allLastBiteCalendarIds();
    for (final calendarId in ids) {
      try {
        // Dibatasi waktu — di sejumlah device panggilan native ini bisa
        // hang tanpa pernah throw atau selesai, yang tanpa timeout bakal
        // bikin seluruh antrean sinkron macet di item ini selamanya.
        await _plugin.deleteEvent(calendarId, eventId).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }
}
