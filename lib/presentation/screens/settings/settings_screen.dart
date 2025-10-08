// lib/presentation/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import '../../../core/config/app_constants.dart';
import 'help_screen.dart';
import 'developer_screen.dart';

/// 설정 화면
/// 앱 설정 및 환경설정을 관리하는 화면
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConstants.backgroundSecondary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            title: '앱 정보',
            children: [
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: '버전',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: '도움말',
                subtitle: '사용 가이드 및 알림 설정',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpScreen(),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.developer_mode,
                title: '개발자 옵션',
                subtitle: '테스트 및 디버깅 도구',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeveloperScreen(),
                    ),
                  );
                },
              )
            ],
          ),
        ],
      ),
    );
  }

  /// 설정 섹션 빌드
  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppConstants.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// 설정 항목 타일 빌드
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white54,
      ),
      onTap: onTap,
    );
  }
}