import 'package:flutter/material.dart';
import 'package:janus_streaming_app/presentation/screens/main_navigation_screen.dart';
import 'core/config/theme_config.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';

/// 애플리케이션의 루트 위젯
/// MaterialApp을 구성하고 테마, 라우팅 등의 앱 전역 설정을 관리
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Janus Streaming',
      theme: ThemeConfig.darkTheme, // 앱 전체에 적용될 다크 테마
      home: const MainNavigationScreen(), // DashboardScreen 대신 MainNavigationScreen으로 변경
    );
  }
}