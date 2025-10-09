import 'package:flutter/material.dart';
import 'app.dart';
import 'data/services/notification_service.dart';
import 'data/services/background_service.dart';  // 추가
import 'package:permission_handler/permission_handler.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 먼저 앱 실행
  runApp(const App());

  // 앱 실행 후 초기화
  Future.delayed(Duration(seconds: 2), () async {
    try {
      // 배터리 최적화 해제 요청
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }

      // 알림 서비스 초기화
      await NotificationService.init();
      print('알림 서비스 초기화 성공');

      // 백그라운드 서비스 초기화
      await BackgroundService.initialize();
      print('백그라운드 서비스 초기화 성공');
    } catch (e) {
      print('초기화 중 오류: $e');
    }
  });
}