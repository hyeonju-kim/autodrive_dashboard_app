// lib/presentation/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'jeju/jeju_screen.dart';
import 'settings/settings_screen.dart';

/// 하단 네비게이션 바를 포함한 메인 화면
/// 3개의 탭 (제주, 화성, 설정)을 관리
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  /// 현재 선택된 탭 인덱스
  int _currentIndex = 1; // 화성 탭을 기본으로 설정

  /// 각 탭에 해당하는 화면들
  final List<Widget> _screens = [
    const JejuScreen(),      // 0: 제주
    const DashboardScreen(), // 1: 화성 (기존 대시보드)
    const SettingsScreen(),  // 2: 설정
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue[700],
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.location_city),
              label: '제주',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rocket_launch),
              label: '화성',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}