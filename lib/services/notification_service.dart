// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/food_item.dart';

// Pengingat expiry lewat notifikasi lokal (H-1 dan H, jam 09:00 waktu lokal).
// Semua method aman dipanggil berkali-kali / gagal diam-diam kalau OS
// menolak izin — app tetap harus jalan normal tanpa fitur ini.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Gagal deteksi timezone device — tetap lanjut pakai default plugin
      // daripada bikin seluruh init gagal.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
        await android?.requestExactAlarmsPermission();
      } else if (Platform.isIOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (_) {}
  }

  // Dua id notif deterministik per item (H-1 dan H) supaya reschedule =
  // cancel lama + jadwalkan ulang, bukan numpuk notif duplikat.
  static int _h1Id(String foodId) => (foodId.hashCode & 0x7fffffff) % 1000000 * 2;
  static int _hDayId(String foodId) => _h1Id(foodId) + 1;

  static Future<void> scheduleForFood(FoodItem food) async {
    if (!_initialized) await init();
    await cancelForFood(food.id);

    const androidDetails = AndroidNotificationDetails(
      'expiry_reminders',
      'Pengingat Expired',
      channelDescription: 'Notifikasi saat bahan makanan mendekati atau sudah expired',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    final expiry = food.expiryDate;
    final hDay = DateTime(expiry.year, expiry.month, expiry.day, 9, 0);
    final h1 = hDay.subtract(const Duration(days: 1));

    Future<void> scheduleAt(int id, DateTime when, String title, String body) async {
      if (when.isBefore(DateTime.now())) return;
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(when, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }

    await scheduleAt(_h1Id(food.id), h1, '⏰ ${food.name} expired besok!', '${food.quantity} ${food.unit} akan expired besok, cek kulkasmu.');
    await scheduleAt(_hDayId(food.id), hDay, '🚨 ${food.name} expired hari ini!', '${food.quantity} ${food.unit} expired hari ini, segera diolah atau dibuang.');
  }

  static Future<void> cancelForFood(String foodId) async {
    try {
      await _plugin.cancel(_h1Id(foodId));
      await _plugin.cancel(_hDayId(foodId));
    } catch (_) {}
  }
}
