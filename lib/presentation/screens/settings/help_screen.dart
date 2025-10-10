// lib/presentation/screens/settings/help_screen.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/config/app_constants.dart';

/// 도움말 화면
/// 사용 가이드 및 알림 설정 방법 안내
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          '도움말',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConstants.backgroundSecondary,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 5,
          ),
          children: [
            _buildHelpSection(
              title: '백그라운드 알림 설정',
              icon: Icons.notifications_active,
              iconColor: Colors.blue,
              context: context,
              children: [
                _buildSimpleGuide(
                  text: '• 알림 권한 허용\n'
                      '• 배터리 최적화 해제\n'
                      '• 백그라운드 데이터 허용\n'
                      '• 절전모드 해제',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildHelpSection(
              title: '앱 사용 가이드',
              icon: Icons.help_outline,
              iconColor: Colors.green,
              context: context,
              children: [
                _buildGuideItem(
                  icon: Icons.dashboard,
                  title: '대시보드 화면',
                  description: 'MQTT 실시간 데이터인 차량 데이터 및 실시간 영상 스트림을 확인할 수 있습니다. \n영상은 wireguard VPN 설정을 킨 상태여야 합니다.',
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildGuideItem(
                  icon: Icons.notifications,
                  title: '알람 서비스',
                  description: '차량 메시지가 종료된 후 ${AppConstants.dataTimeoutMinutes}분이 지난 후에 다시 차량 메시지가 수신될 경우 알람을 발송합니다. \n앱을 모두 종료하면 알림을 받을 수 없으니 스와이프로 앱을 종료하지 말고 백그라운드에서 동작하게 해주세요.',
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildGuideItem(
                  icon: Icons.battery_alert,
                  title: '배터리 소모',
                  description: '차량 실시간 메시지 알람 서비스를 위해 백그라운드 모드로 1분마다 상태를 체크하므로 배터리 소모가 있을 수 있습니다. 원하지 않으시면 개발자 옵션에서 \'백그라운드 서비스 중지\'를 눌러주세요.',
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildGuideItem(
                  icon: Icons.refresh,
                  title: '새로고침',
                  description: '화면을 아래로 당겨서 연결을 새로고침할 수 있습니다. 버벅임이 있는 경우 앱을 껐다 키거나 개발자 옵션에서 캐시 초기화를 해주세요.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 도움말 섹션 (버튼 포함)
  Widget _buildHelpSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required BuildContext context,
    required List<Widget> children,
  }) {
    // 백그라운드 알림 설정 섹션인지 확인
    final isNotificationSection = icon == Icons.notifications_active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // 백그라운드 알림 설정일 때만 버튼 표시
              if (isNotificationSection)
                ElevatedButton.icon(
                  onPressed: () => _openAppSettings(context),
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('앱 설정 열기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// 간단한 가이드 (박스 하나로 통합, 상세 텍스트 유지)
  Widget _buildSimpleGuide({required String text}) {
    return Column(
      children: [
        _buildSettingRow('알림 권한 허용', '설정 > 애플리케이션 > 앱 선택 > 알림 > 알림 허용'),
        const Divider(color: Colors.white12, height: 24),
        _buildSettingRow('배터리 최적화 해제', '설정 > 애플리케이션 > 앱 선택 > 배터리 > 제한 없음'),
        const Divider(color: Colors.white12, height: 24),
        _buildSettingRow('백그라운드 데이터 허용', '설정 > 애플리케이션 > 앱 선택 > 모바일 데이터 > 백그라운드 데이터 허용'),
        const Divider(color: Colors.white12, height: 24),
        _buildSettingRow('절전모드 해제', '설정 > 배터리 > 절전 모드 > 사용 OFF'),
      ],
    );
  }

  /// 설정 항목 행 (앱 사용가이드와 동일한 스타일)
  Widget _buildSettingRow(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.blue, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 가이드 항목
  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 앱 설정 열기
  Future<void> _openAppSettings(BuildContext context) async {
    try {
      await openAppSettings();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('설정 화면을 열었습니다')),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('설정 화면 열기 실패: $e')),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}