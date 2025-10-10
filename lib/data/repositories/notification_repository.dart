// lib/data/repositories/notification_repository.dart

import 'dart:convert';
import 'package:janus_streaming_app/core/config/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationRepository {
  static const _key = 'saved_notifications';
  static const int _maxNotifications = AppConstants.maxAlarmCount; // 최대 100개까지만 유지

  /// 알람 리스트에 추가
  static Future<void> addNotification(NotificationItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(jsonEncode(item.toJson()));

    // 오래된 알림 삭제
    if (list.length > _maxNotifications) {
      list.removeRange(0, list.length - _maxNotifications);
    }

    await prefs.setStringList(_key, list);
  }

  /// 알람 목록 조회
  static Future<List<NotificationItem>> getAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final items = raw
        .map((e) => NotificationItem.fromJson(jsonDecode(e)))
        .toList();

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 내림차순(최신순)
    return items;
  }

  /// 알람 리스트 전체 저장
  static Future<void> saveAll(List<NotificationItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  /// 알람 전체 삭제
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }


}
