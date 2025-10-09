// lib/services/background_service.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_constants.dart';
import '../../core/utils/logger.dart';


/// 백그라운드 서비스 관리 클래스
///
/// 앱이 종료되어도 계속 실행되는 백그라운드/포그라운드 서비스를 관리합니다.
/// 주기적으로 차량 상태를 확인하고 필요시 사용자에게 알림을 발송합니다.
class BackgroundService {
  // ===== 설정 가능한 상수들 =====

  /// 상태 확인 주기 (분)
  /// 백그라운드에서 차량 상태를 확인하는 주기
  static const int _checkIntervalMinutes = AppConstants.checkIntervalMinutes;

  /// 데이터 타임아웃 시간 (분)
  /// 이 시간 동안 데이터가 업데이트되지 않으면 문제로 판단
  static const int _dataTimeoutMinutes = AppConstants.dataTimeoutMinutes;

  /// 재연결 알림 활성화 여부
  static const bool _enableReconnectionNotification = true;

  /// SharedPreferences 키 상수
  static const String _keyLastDataTime = 'last_data_time';
  static const String _keyVehicleId = 'current_vehicle_id';
  static const String _keyVehicleNumber = 'current_vehicle_number';
  static const String _keyIsDisconnected = 'is_disconnected';
  static const String _keyIsResetState = 'is_reset_state';
  static const String _keyPort = 'current_port';  // 포트 정보 추가
  static const String _keyDisconnectedTime = 'disconnected_time'; // 끊어진 시간
  static const String _keyResetTime = 'reset_time'; // 리셋 시간 추가

  /// 알림 메시지 템플릿
  static const String _notificationTitleTemplate = '{location} - {vehicle}';
  static const String _notificationBodyTemplate = '차량 데이터 수신을 시작합니다.';

  // 로컬 알림을 발송하기 위한 플러그인 인스턴스
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  /// 백그라운드 서비스 초기화
  ///
  /// 앱 시작 시 한 번만 호출되며, 다음 작업을 수행합니다:
  /// 1. Android 알림 채널 생성 (Android 8.0 이상 필수)
  /// 2. 백그라운드 서비스 구성 및 콜백 함수 등록
  /// 3. iOS 백그라운드 작업 설정
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Android 알림 채널 생성
    // Android 8.0(API 26) 이상에서는 모든 알림이 채널에 할당되어야 함
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vehicle_monitoring', // 채널 ID (고유해야 함)
      '차량 모니터링', // 채널 이름 (사용자에게 표시됨)
      description: '차량 상태를 실시간으로 모니터링합니다.', // 채널 설명
      importance: Importance.low, // 중요도 설정 (low: 소리 없음, 상태바에만 표시)
    );

    // Flutter 로컬 알림 플러그인 인스턴스 생성
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    // Android 플랫폼에서 알림 채널 생성
    // null 체크를 통해 Android가 아닌 플랫폼에서도 안전하게 실행
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 백그라운드 서비스 구성
    await service.configure(
      // Android 설정
      androidConfiguration: AndroidConfiguration(
        // 백그라운드에서 실행될 함수 지정 (최상위 함수여야 함)
        onStart: onStart,

        // 앱 시작 시 자동으로 서비스 시작
        autoStart: true,

        // 포그라운드 서비스로 실행 (Android 8.0 이상에서 백그라운드 제한 회피)
        isForegroundMode: true,

        // 포그라운드 서비스 알림에 사용할 채널 ID
        notificationChannelId: 'vehicle_monitoring',

        // 포그라운드 서비스 알림의 초기 제목
        initialNotificationTitle: '차량 모니터링 중',

        // 포그라운드 서비스 알림의 초기 내용
        initialNotificationContent: '백그라운드에서 차량 상태를 확인하고 있습니다.',

        // 포그라운드 서비스 알림 ID (고유해야 함)
        foregroundServiceNotificationId: 888,
      ),

      // iOS 설정
      iosConfiguration: IosConfiguration(
        // iOS에서도 자동 시작 활성화
        autoStart: true,

        // iOS에서 포그라운드 상태일 때 실행할 함수
        onForeground: onStart,
      ),
    );
  }

  /// 백그라운드 서비스 수동 시작
  ///
  /// 서비스가 실행 중이 아닐 때만 시작합니다.
  /// 주로 사용자가 설정에서 서비스를 수동으로 켜고 끌 때 사용합니다.
  static Future<void> startService() async {
    final service = FlutterBackgroundService();

    // 서비스가 이미 실행 중인지 확인
    var isRunning = await service.isRunning();

    // 실행 중이 아니라면 시작
    if (!isRunning) {
      service.startService();
    }
  }

  /// 백그라운드 서비스 중지
  ///
  /// 실행 중인 서비스에 'stopService' 이벤트를 전송하여 종료합니다.
  /// onStart 함수에서 이 이벤트를 수신하여 처리합니다.
  static Future<void> stopService() async {
    final service = FlutterBackgroundService();

    // 서비스가 실행 중인지 확인
    var isRunning = await service.isRunning();

    // 실행 중이라면 중지 이벤트 전송
    if (isRunning) {
      service.invoke("stopService");
    }
  }

  /// 메인 앱에서 차량 데이터 업데이트 시 호출할 함수
  ///
  /// MQTT 서비스에서 데이터를 받을 때마다 이 함수를 호출하여
  /// 백그라운드 서비스가 상태를 추적할 수 있도록 함
  static Future<void> updateLastDataTime({
    required String vehicleId,
    String? vehicleNumber,
    int? port,
    bool isReset = false,
    DateTime? resetTime,  // 리셋 시간 파라미터 추가
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // 현재 시간을 마지막 데이터 수신 시간으로 저장
      await prefs.setInt(_keyLastDataTime, currentTime);

      // 차량 정보 저장
      await prefs.setString(_keyVehicleId, vehicleId);
      if (vehicleNumber != null) {
        await prefs.setString(_keyVehicleNumber, vehicleNumber);
      }
      if (port != null) {
        await prefs.setInt(_keyPort, port);
      }

      // 리셋 상태 저장
      if (isReset) {
        await prefs.setBool(_keyIsResetState, true);
        // 리셋 시간 저장 (바로 끊긴 시간으로 기록)
        if (resetTime != null) {
          await prefs.setInt(_keyResetTime, resetTime.millisecondsSinceEpoch);
          await prefs.setInt(_keyDisconnectedTime, resetTime.millisecondsSinceEpoch);
          await prefs.setBool(_keyIsDisconnected, true);
          Logger.log('[메인앱] 리셋 시간 기록: ${resetTime.toString()}');
        }
      } else {
        await prefs.setBool(_keyIsResetState, false);
        // 데이터 수신 시 연결 상태 복구
        await prefs.setBool(_keyIsDisconnected, false);
        await prefs.remove(_keyDisconnectedTime);
        await prefs.remove(_keyResetTime);
      }

      // 명시적으로 저장
      await prefs.reload();

      // 저장 후 확인 로그
      final savedTime = prefs.getInt(_keyLastDataTime);
      // Logger.log('[메인앱] SharedPreferences 업데이트 완료 - 저장된 시간: ${DateTime.fromMillisecondsSinceEpoch(savedTime ?? 0)}');

    } catch (e) {
      Logger.log('[메인앱] SharedPreferences 업데이트 실패: $e');
    }
  }
}

/// 백그라운드에서 실행될 메인 함수
///
/// 이 함수는 별도의 isolate에서 실행되므로:
/// 1. 최상위(top-level) 함수여야 함
/// 2. UI 관련 작업 불가
/// 3. 메인 isolate와 메모리 공유 불가 (SharedPreferences 등은 가능)
///
/// @pragma('vm:entry-point')는 Flutter가 이 함수를 제거하지 않도록 보장
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Flutter 엔진의 플러그인 등록
  // 백그라운드 isolate에서 플러그인을 사용하기 위해 필수
  DartPluginRegistrant.ensureInitialized();

  // 로컬 알림 플러그인 인스턴스 생성
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // 알림 플러그인 초기화
  // @mipmap/ic_launcher는 앱 아이콘을 알림 아이콘으로 사용
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 서비스 시작 로그
  Logger.log('[백그라운드] 서비스 시작됨 - ${DateTime.now()}');

  // 'stopService' 이벤트 리스너 등록
  // stopService() 메서드가 호출되면 이 이벤트가 발생
  service.on('stopService').listen((event) {
    Logger.log('[백그라운드] 서비스 중지 요청받음');
    service.stopSelf(); // 서비스 자체 종료
  });

  // 주기적 작업 설정 (1분마다 실행)
  // 실제 운영 환경에서는 배터리 소모를 고려하여 주기를 조정해야 함
  Timer.periodic(Duration(minutes: BackgroundService._checkIntervalMinutes), (timer) async {
    // 체크 시작 로그
    Logger.log('[백그라운드] 상태 체크 시작 - ${DateTime.now()}');

    // SharedPreferences에서 데이터 읽기
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // 강제 새로고침

    final lastDataTime = prefs.getInt(BackgroundService._keyLastDataTime) ?? 0;
    final vehicleId = prefs.getString(BackgroundService._keyVehicleId);

    if (lastDataTime > 0) {
      final lastDataDateTime = DateTime.fromMillisecondsSinceEpoch(lastDataTime);
      final diff = DateTime.now().difference(lastDataDateTime);
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      Logger.log('[백그라운드] 차량ID: $vehicleId, 마지막 데이터: ${lastDataDateTime.toString()}, 경과시간: $minutes분 $seconds초');

    } else {
      Logger.log('[백그라운드] 저장된 데이터 없음');
    }

    // 차량 상태 및 연결 상태 확인
    final alertInfo = await checkVehicleStatus();

    if (alertInfo != null) {
      // 문제가 감지되면 사용자에게 알림 발송
      Logger.log('[백그라운드] 알림 발송: ${alertInfo['title']} - ${alertInfo['body']}');
      await showNotification(
        flutterLocalNotificationsPlugin,
        alertInfo['title']!,
        alertInfo['body']!,
      );
    } else {
      Logger.log('[백그라운드] 정상 상태 - 알림 없음');
    }

    // Android 플랫폼에서만 포그라운드 서비스 알림 업데이트
    // iOS는 포그라운드 서비스 개념이 없음
    if (service is AndroidServiceInstance) {
      // 포그라운드 서비스가 활성화되어 있는지 확인
      if (await service.isForegroundService()) {
        // 포그라운드 서비스 알림 내용 업데이트
        // 사용자에게 서비스가 정상 작동 중임을 알림
        // Logger.log('[백그라운드] 포그라운드 알림 업데이트');
        service.setForegroundNotificationInfo(
          title: "차량 모니터링 중",
          content: "마지막 확인: ${DateTime.now().toString().substring(11, 19)}",
        );
      }
    }
  });
}

/// 차량 상태 확인 함수
///
/// MQTT 서비스의 로직을 참고하여 구현
/// SharedPreferences에서 상태를 읽어 타임아웃 및 재연결을 감지
///
/// 반환값:
/// - Map<String, String>: 알림 제목과 내용 (알림이 필요한 경우)
/// - null: 정상 상태, 알림 불필요
Future<Map<String, String>?> checkVehicleStatus() async {
  final prefs = await SharedPreferences.getInstance();

  // SharedPreferences 강제 새로고침
  await prefs.reload();

  // 저장된 상태 정보 읽기
  final lastDataTime = prefs.getInt(BackgroundService._keyLastDataTime) ?? 0;
  final vehicleId = prefs.getString(BackgroundService._keyVehicleId);
  final vehicleNumber = prefs.getString(BackgroundService._keyVehicleNumber);
  final port = prefs.getInt(BackgroundService._keyPort);
  final wasDisconnected = prefs.getBool(BackgroundService._keyIsDisconnected) ?? false;
  final disconnectedTime = prefs.getInt(BackgroundService._keyDisconnectedTime) ?? 0;
  final resetTime = prefs.getInt(BackgroundService._keyResetTime) ?? 0;
  final isResetState = prefs.getBool(BackgroundService._keyIsResetState) ?? false;

  // 디버깅 로그
  Logger.log('[백그라운드] checkVehicleStatus - wasDisconnected: $wasDisconnected, isResetState: $isResetState');

  // 차량 정보가 없으면 모니터링하지 않음
  if (vehicleId == null) {
    Logger.log('[백그라운드] 차량 정보 없음 - 모니터링 중단');
    return null;
  }

  // 현재 시간과 마지막 데이터 수신 시간 비교
  final now = DateTime.now().millisecondsSinceEpoch;
  final timeDiff = now - lastDataTime;
  final timeoutMillis = BackgroundService._dataTimeoutMinutes * 60 * 1000;

  // 리셋 상태에서 벗어났는지 확인 (메인 앱에서 리셋 해제했는지)
  if (!isResetState && wasDisconnected && resetTime > 0) {
    // 리셋 시간과 현재 시간 비교
    final resetTimeDiff = now - resetTime;
    final resetTimeDiffMinutes = resetTimeDiff / 1000 / 60;

    Logger.log('[백그라운드] 리셋 후 데이터 수신 - 리셋으로부터 경과시간: ${resetTimeDiffMinutes.toStringAsFixed(1)}분');

    // 10분 이상 경과했으면 알림 발송
    if (resetTimeDiffMinutes >= BackgroundService._dataTimeoutMinutes && BackgroundService._enableReconnectionNotification) {
      final location = _getLocationName(vehicleId, port);
      final vehicleInfo = vehicleNumber ?? vehicleId;

      final title = BackgroundService._notificationTitleTemplate
          .replaceAll('{location}', location)
          .replaceAll('{vehicle}', vehicleInfo);

      Logger.log('[백그라운드] ✅ 리셋 재연결 알림 발송! (${resetTimeDiffMinutes.toStringAsFixed(1)}분 동안 끊어졌었음)');
      return {
        'title': title,
        'body': BackgroundService._notificationBodyTemplate,
      };
    }
  }

  // 일반 타임아웃 상태에서 재연결된 경우
  if (wasDisconnected && !isResetState && timeDiff <= timeoutMillis && disconnectedTime > 0) {
    // 끊어졌던 시간 계산
    final disconnectedDuration = now - disconnectedTime;
    final disconnectedMinutes = disconnectedDuration / 1000 / 60;

    if (disconnectedMinutes >= BackgroundService._dataTimeoutMinutes && BackgroundService._enableReconnectionNotification) {
      final location = _getLocationName(vehicleId, port);
      final vehicleInfo = vehicleNumber ?? vehicleId;

      final title = BackgroundService._notificationTitleTemplate
          .replaceAll('{location}', location)
          .replaceAll('{vehicle}', vehicleInfo);

      Logger.log('[백그라운드] ✅ 일반 재연결 알림 발송! (${disconnectedMinutes.toStringAsFixed(1)}분 동안 끊어졌었음)');
      return {
        'title': title,
        'body': BackgroundService._notificationBodyTemplate,
      };
    }
  }

  Logger.log('[백그라운드] 정상 상태 - 알림 없음');
  return null;
}

/// 지역명 가져오기 (vehicleId와 포트 기반)
///
/// MQTT 서비스의 로직과 동일하게 구현
/// AppConstants를 직접 참조할 수 없으므로 하드코딩
String _getLocationName(String vehicleId, int? port) {
  // AppConstants의 실제 vehicleId 값 사용

  // 화성 차량
  if (vehicleId == 'f4FwwkGR') {
    return '화성';
  }

  // 제주 차량
  if (vehicleId == 'VEHICLEID') {
    return '제주';
  }

  // 포트 번호로도 구분 가능 (vehicleId가 없거나 잘못된 경우)
  if (port == 38083) {
    return '화성';
  } else if (port == 28083) {
    return '제주';
  }

  return '알 수 없음';
}

/// 로컬 알림 표시 함수
///
/// 사용자의 기기에 알림을 표시합니다.
/// 백그라운드에서도 작동하며, 알림을 탭하면 앱이 열립니다.
///
/// Parameters:
/// - plugin: 알림 플러그인 인스턴스
/// - title: 알림 제목
/// - body: 알림 내용
Future<void> showNotification(
    FlutterLocalNotificationsPlugin plugin,
    String title,
    String body,
    ) async {
  // Android 알림 상세 설정
  const androidDetails = AndroidNotificationDetails(
    'vehicle_alerts', // 채널 ID (알림 채널과 연결)
    '차량 알림', // 채널 이름
    channelDescription: '차량 상태 알림', // 채널 설명
    importance: Importance.high, // 중요도 (high: 소리와 헤드업 알림)
    priority: Priority.high, // 우선순위 (high: 즉시 표시)
    icon: '@mipmap/ic_launcher', // 알림 아이콘
    playSound: true, // 소리 재생
    enableVibration: true, // 진동
    autoCancel: true, // 탭하면 자동 제거
  );

  // 플랫폼별 알림 설정 통합
  const details = NotificationDetails(android: androidDetails);

  // 알림 표시
  // ID를 32비트 정수 범위로 제한
  final id = DateTime.now().millisecondsSinceEpoch % 2147483647;

  await plugin.show(
    id, // 수정된 알림 ID (32비트 범위)
    title, // 알림 제목
    body, // 알림 내용
    details, // 알림 상세 설정
  );
}