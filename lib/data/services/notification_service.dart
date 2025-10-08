// lib/data/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/utils/logger.dart';

/// 📢 알림 서비스
/// 앱이 백그라운드에 있거나 종료된 상태에서도 주기적으로 알림을 보내는 서비스
///
/// 주요 기능:
/// - 알림 채널 생성 및 초기화
/// - 백그라운드 작업 예약 (WorkManager 사용)
/// - 알림 표시
class NotificationService {
  // 📱 알림 채널 설정 (Android 8.0 이상 필수)
  // 같은 채널 ID를 사용하는 알림들은 같은 설정을 공유함
  static const String _channelId = 'periodic_notification';
  static const String _channelName = '주기적 알림';
  static const String _taskName = 'periodicTask';

  // 🔔 Flutter Local Notifications 플러그인 인스턴스
  // 실제로 알림을 표시하는 역할 (카메라)
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  /// 🚀 알림 서비스 초기화
  /// 앱 시작 시 main.dart에서 호출해야 함
  ///
  /// 수행 작업:
  /// 1. 플랫폼별 초기화 설정 (Android/iOS)
  /// 2. 알림 채널 생성
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
    // Android 8.0(Oreo) 이상에서는 알림 채널이 필수
    // 사용자가 설정 > 앱 > 알림에서 이 채널을 볼 수 있음
    const androidChannel = AndroidNotificationChannel(
      _channelId,           // 채널 고유 ID
      _channelName,         // 사용자에게 보이는 채널 이름
      importance: Importance.high,  // 중요도: 높음 (소리 + 헤드업 알림)
      enableVibration: true,        // 진동 켜기
    );

    // Android 전용 기능에 접근하여 채널 생성
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    Logger.log('✅ 알림 서비스 초기화 완료');
  }

  /// ⏰ 백그라운드 작업 시작
  /// WorkManager를 사용하여 주기적으로 알림을 보내도록 예약
  ///
  /// 중요:
  /// - Android의 PeriodicTask 최소 간격은 15분
  /// - 1분으로 설정해도 시스템이 15분으로 조정함
  /// - 배터리 절약을 위한 Android 정책
  static Future<void> startBackgroundTask() async {
    // ⏰ WorkManager 초기화 (타이머 로봇 깨우기)
    // callbackDispatcher: 예약된 시간에 실행될 함수
    // isInDebugMode: false = 디버그 로그 끄기 (배포용)
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // 📅 주기적 작업 등록 (반복 예약)
    // 15분마다 callbackDispatcher 함수가 자동으로 실행됨
    await Workmanager().registerPeriodicTask(
      _taskName,            // 작업 고유 이름 (같은 이름으로 등록하면 덮어씀)
      _taskName,            // 작업 타입 (콜백에서 구분용)
      frequency: const Duration(minutes: 1), // ⚠️ 실제로는 15분으로 조정됨!
      constraints: Constraints(
        networkType: NetworkType.notRequired, // 와이파이 없어도 실행
      ),
    );

    Logger.log('✅ 백그라운드 작업 시작');
  }

  /// 🔔 실행 후 1분 뒤 알람 오도록 설정 (1회성)
  ///
  /// 주의:
  /// - registerOneOffTask는 단 한 번만 실행됨
  /// - 반복하려면 registerPeriodicTask 사용
  /// - 1분 후 "약" 실행됨 (정확하지 않음)
  // static Future<void> startBackgroundTask() async {
  //   // ⏰ WorkManager 초기화
  //   await Workmanager().initialize(callbackDispatcher);
  //
  //   // 📅 1회성 작업 등록 (한 번만 실행)
  //   await Workmanager().registerOneOffTask(
  //     'oneOffTask',        // 작업 고유 이름
  //     'oneOffTask',        // 작업 타입
  //     initialDelay: const Duration(minutes: 1), // 1분 후 실행
  //   );
  //
  //   Logger.log('✅ 1회성 작업 등록 (1분 후 실행)');
  // }

  /// 📢 알림 표시
  /// 실제로 사용자에게 알림을 보여주는 함수
  ///
  /// 호출 방법:
  /// 1. 버튼 클릭 시 (즉시 테스트용)
  /// 2. WorkManager의 callbackDispatcher에서 자동 호출
  static Future<void> showNotification() async {
    // 📅 현재 시간 가져오기
    final now = DateTime.now();

    // 🕐 시간을 "2025-10-08 19:30:45" 형식으로 변환
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    // 🤖 Android 알림 상세 설정
    const androidDetails = AndroidNotificationDetails(
      _channelId,                    // 어떤 채널로 보낼지 (init에서 생성한 채널)
      _channelName,                  // 채널 이름
      importance: Importance.high,   // 중요도: 높음 (소리 + 헤드업)
      priority: Priority.high,       // 우선순위: 높음 (알림 트레이 상단)
      showWhen: true,                // 알림에 시간 표시
    );

    // 📱 플랫폼별 알림 설정을 하나로 묶음
    const details = NotificationDetails(android: androidDetails);

    // 🔔 알림 표시!
    await _notifications.show(
      0,                             // 알림 ID (0 = 같은 알림을 계속 덮어씀)
      '자율주행 관제 임시앱',          // 알림 제목
      '지금은 $formattedDate입니다.',  // 알림 내용
      details,                       // 알림 상세 설정
    );
  }

  /// ⛔ 백그라운드 작업 중지
  /// 등록된 모든 WorkManager 작업을 취소
  ///
  /// 사용 예:
  /// - 사용자가 알림을 끄고 싶을 때
  /// - 앱 설정에서 알림 기능 비활성화할 때
  static Future<void> stopBackgroundTask() async {
    // ⏰ 모든 예약 작업 취소
    await Workmanager().cancelAll();
    Logger.log('✅ 백그라운드 작업 중지');
  }
}

/// 🤖 백그라운드에서 실행될 콜백 함수
///
/// 중요:
/// - @pragma('vm:entry-point') 필수! (코드 난독화 시 삭제 방지)
/// - WorkManager가 예약된 시간에 이 함수를 자동으로 호출
/// - 앱이 종료되어 있어도 실행됨
///
/// 실행 흐름:
/// 1. WorkManager: "시간 됐어! callbackDispatcher 실행!"
/// 2. callbackDispatcher: "알겠어! showNotification() 호출!"
/// 3. showNotification(): "사용자에게 알림 표시!"
@pragma('vm:entry-point')
void callbackDispatcher() {
  // ⏰ WorkManager의 작업 실행기
  Workmanager().executeTask((task, inputData) async {
    // 📢 알림 표시
    await NotificationService.showNotification();

    // ✅ 작업 성공 반환
    // true = 성공, false = 실패 (재시도됨)
    return Future.value(true);
  });
}