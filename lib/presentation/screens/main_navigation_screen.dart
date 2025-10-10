// lib/presentation/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'settings/settings_screen.dart';
import '../../../core/config/app_constants.dart';

/// 탭 기반 메인 화면
/// 제주/화성을 탭과 스와이프로 전환
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1); // 화성부터 시작
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundSecondary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '자율주행 관제 대시보드',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white70,
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Transform.translate(
            offset: const Offset(0, -8),
          child: Container(
            decoration: BoxDecoration(
              color: AppConstants.backgroundSecondary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.transparent,
              labelPadding: EdgeInsets.zero,
              tabs: [
                _buildTab('제주', 0, Colors.blue),
                _buildTab('화성', 1, Colors.blue),
              ],
            ),
          ),
        ),),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardScreen(isMars: false, hideAppBar: true), // 제주
          DashboardScreen(isMars: true, hideAppBar: true),  // 화성
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, Color color) {
    return AnimatedBuilder(
      animation: _tabController.animation!,
      builder: (context, child) {
        // 현재 탭과의 거리 계산 (0.0 = 선택됨, 1.0 = 선택 안 됨)
        final isSelected = _tabController.index == index;
        final animationValue = (_tabController.animation!.value - index).abs();
        final progress = (1.0 - animationValue).clamp(0.0, 1.0);

        return Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: color.withOpacity(progress * 0.8),
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: Color.lerp(
                        Colors.white.withOpacity(0.5),
                        color,
                        progress,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}