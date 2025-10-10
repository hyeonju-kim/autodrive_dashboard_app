// lib/presentation/screens/settings/app_info_screen.dart

import 'package:flutter/material.dart';
import '../../../core/config/app_constants.dart';

/// 앱 정보 상세 화면
class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          '앱 정보',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConstants.backgroundSecondary,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 20, // ✅ 하단 패딩 추가
        ),
        children: [
          // 앱 아이콘 및 이름
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '자율주행 관제 앱',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 빌드 정보
          _buildInfoSection(
            title: '빌드 정보',
            children: [
              _buildInfoRow('앱 버전', '1.0.0'),
              _buildInfoRow('빌드 번호', '1'),
              _buildInfoRow('패키지 이름', 'com.example.test_project'),
            ],
          ),
          const SizedBox(height: 16),

          // 프레임워크 정보
          _buildInfoSection(
            title: '프레임워크',
            children: [
              _buildInfoRow('Flutter', '3.35.5'),
              _buildInfoRow('Dart', '3.9.2'),
              _buildInfoRow('DevTools', '2.48.0'),
            ],
          ),
          const SizedBox(height: 16),

          // Android 정보
          _buildInfoSection(
            title: 'Android',
            children: [
              _buildInfoRow('Compile SDK', '36'),
              _buildInfoRow('Target SDK', '36'),
              _buildInfoRow('Min SDK', '21 (Android 5.0)'),
              _buildInfoRow('Kotlin', '1.9+'),
              _buildInfoRow('Java', '17'),
            ],
          ),
          const SizedBox(height: 16),

          // 주요 라이브러리
          _buildInfoSection(
            title: '주요 라이브러리',
            children: [
              _buildInfoRow('flutter_webrtc', '0.9.12'),
              _buildInfoRow('mqtt_client', '9.8.1'),
              _buildInfoRow('provider', '6.1.1'),
              _buildInfoRow('http', '0.13.6'),
              _buildInfoRow('intl', '0.18.0'),
              _buildInfoRow('web_socket_channel', '2.4.0'),
              _buildInfoRow('flutter_local_notifications', '17.2.3'),
              _buildInfoRow('flutter_background_service', '5.0.5'),
              _buildInfoRow('permission_handler', '11.1.0'),
              _buildInfoRow('shared_preferences', '2.2.2'),
              _buildInfoRow('workmanager', 'github/main'),
            ],
          ),
        ],
      ),
    );
  }

  /// 정보 섹션
  Widget _buildInfoSection({
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
              fontSize: 15,
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

  /// 정보 행
  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}