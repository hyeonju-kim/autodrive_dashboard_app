import 'package:flutter/material.dart';
import 'app.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 알림 서비스 초기화
  await NotificationService.init();
  await NotificationService.startBackgroundTask();

  runApp(const App());
}