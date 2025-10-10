// lib/data/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../../core/utils/logger.dart';

/// 📢 알림 서비스
/// 앱에서 사용자에게 알림을 표시하는 서비스
///
/// 주요 기능:
/// - 알림 채널 생성 및 초기화
/// - 알림 표시 (테스트용, 차량 메시지용)
class NotificationService {
  // 📱 알림 채널 설정 (Android 8.0 이상 필수)
  static const String _channelId = 'vehicle_notification';
  static const String _channelName = '차량 알림';

  // 🔔 Flutter Local Notifications 플러그인 인스턴스
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  /// 🚀 알림 서비스 초기화
  /// 앱 시작 시 main.dart에서 호출해야 함
  static Future<void> init() async {
    // Android 설정: 앱 아이콘을 알림 아이콘으로 사용
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정: 기본 설정 사용
    const iosSettings = DarwinInitializationSettings();

    // 플랫폼별 설정을 하나로 묶음
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 📱 알림 플러그인 초기화
    await _notifications.initialize(initSettings);

    // 📢 Android 알림 채널 생성
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: '차량 관련 알림을 받습니다',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      enableLights: true,
    );

    // Android 전용 기능에 접근하여 채널 생성
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    Logger.log('✅ 알림 서비스 초기화 완료');
  }

  /// 📢 알림 표시
  /// 사용자에게 알림을 보여주는 함수
  ///
  /// [title] 알림 제목
  /// [body] 알림 내용
  ///
  /// 사용 예:
  /// 1. 테스트용 알림
  /// 2. 차량 데이터 재연결 알림
  static Future<void> showNotification({
    String? title,
    String? body,
  }) async {
    Logger.log('🔵 알림 표시 시도');

    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: '차량 관련 알림을 받습니다',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        ticker: '새 알림',
      );

      const details = NotificationDetails(android: androidDetails);

      // ID를 32비트 범위로 제한
      final id = DateTime.now().millisecondsSinceEpoch % 2147483647;

      await _notifications.show(
        id,
        title ?? '자율주행 임시앱',
        body ?? '알림 테스트',
        details,
      );

      Logger.log('✅ 알림 표시 완료: ID=$id');
    } catch (e) {
      Logger.log('❌ 알림 표시 실패: $e');
    }
  }
}