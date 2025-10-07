// lib/presentation/screens/jeju/jeju_screen.dart

import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';

/// 제주 관제 화면
/// DashboardScreen을 재사용하여 제주 데이터 표시
class JejuScreen extends StatelessWidget {
  const JejuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 기존 DashboardScreen을 제주 모드로 사용
    return const DashboardScreen(isMars: false);
  }
}