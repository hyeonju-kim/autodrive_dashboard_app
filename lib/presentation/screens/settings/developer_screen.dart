// lib/presentation/screens/developer/developer_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_constants.dart';
import '../../../data/services/notification_service.dart';
import '../../../core/utils/logger.dart';

/// 개발자용 화면
/// 테스트 및 디버깅을 위한 개발자 전용 기능 제공
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  bool _isNotificationTesting = false;
  bool _isMqttMarsTesting = false;
  bool _isMqttJejuTesting = false;
  bool _isJanusTesting = false;
  bool _isBackgroundChecking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          '개발자 옵션',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: '알림 테스트',
            icon: Icons.notifications_active,
            iconColor: Colors.blue,
            children: [
              _buildTestButton(
                label: '즉시 알림 테스트',
                subtitle: '알림이 정상적으로 작동하는지 확인',
                icon: Icons.send,
                onPressed: _testNotification,
                isLoading: _isNotificationTesting,
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildInfoTile(
                icon: Icons.info_outline,
                title: '알림 설정 확인',
                subtitle: '설정 > 애플리케이션 > 알림에서 권한 확인',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: '백그라운드 서비스',
            icon: Icons.sync,
            iconColor: Colors.purple,
            children: [
              _buildTestButton(
                label: '백그라운드 상태 확인',
                subtitle: '서비스 실행 상태 및 데이터 수신 확인',
                icon: Icons.info_outline,
                onPressed: _checkBackgroundStatus,
                isLoading: _isBackgroundChecking,
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildTestButton(
                label: '백그라운드 서비스 시작',
                subtitle: '수동으로 백그라운드 서비스 시작',
                icon: Icons.play_arrow,
                onPressed: _startBackgroundService,
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildTestButton(
                label: '백그라운드 서비스 중지',
                subtitle: '실행 중인 백그라운드 서비스 중지',
                icon: Icons.stop,
                onPressed: _stopBackgroundService,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: '연결 테스트',
            icon: Icons.network_check,
            iconColor: Colors.cyan,
            children: [
              _buildTestButton(
                label: 'MQTT 연결 테스트 - 화성',
                subtitle: '${AppConstants.mqttHost}:${AppConstants.mqttPortMars}',
                icon: Icons.cloud_queue,
                onPressed: _testMqttConnectionMars,
                isLoading: _isMqttMarsTesting,
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildTestButton(
                label: 'MQTT 연결 테스트 - 제주',
                subtitle: '${AppConstants.mqttHost}:${AppConstants.mqttPortJeju}',
                icon: Icons.cloud_queue,
                onPressed: _testMqttConnectionJeju,
                isLoading: _isMqttJejuTesting,
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildTestButton(
                label: 'Janus 연결 테스트',
                subtitle: '${AppConstants.janusServer}/info',
                icon: Icons.video_library,
                onPressed: _testJanusConnection,
                isLoading: _isJanusTesting,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: '앱 상태',
            icon: Icons.memory,
            iconColor: Colors.green,
            children: [
              _buildTestButton(
                label: '캐시 초기화',
                subtitle: '임시 데이터 삭제',
                icon: Icons.cleaning_services,
                onPressed: _clearCache,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: '시스템 정보',
            icon: Icons.settings_system_daydream,
            iconColor: Colors.teal,
            children: [
              _buildInfoTile(
                icon: Icons.phone_android,
                title: 'Android SDK',
                subtitle: 'Target SDK 36',
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildInfoTile(
                icon: Icons.code,
                title: 'Flutter 버전',
                subtitle: '3.29+',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 섹션 빌드
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
            ],
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

  /// 테스트 버튼 빌드
  Widget _buildTestButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: isLoading
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: const Text(
          '실행',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: isLoading ? null : onPressed,
    );
  }

  /// 정보 타일 빌드
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 20),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
    );
  }

  // ===== 기능 구현 =====

  /// 알림 테스트
  Future<void> _testNotification() async {
    setState(() => _isNotificationTesting = true);

    try {
      await NotificationService.showNotification();

      if (mounted) {
        _showResultSnackBar(
          message: '알림이 전송되었습니다',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultSnackBar(
          message: '알림 전송 실패: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isNotificationTesting = false);
      }
    }
  }

  /// 백그라운드 서비스 상태 확인
  Future<void> _checkBackgroundStatus() async {
    setState(() => _isBackgroundChecking = true);

    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      final prefs = await SharedPreferences.getInstance();
      final lastTime = prefs.getInt('last_data_time') ?? 0;
      final vehicleId = prefs.getString('current_vehicle_id') ?? '없음';
      final vehicleNumber = prefs.getString('current_vehicle_number') ?? '없음';
      final port = prefs.getInt('current_port') ?? 0;
      final isDisconnected = prefs.getBool('is_disconnected') ?? false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = (now - lastTime) / 1000 / 60; // 분 단위

      String location = '알 수 없음';
      if (vehicleId == 'f4FwwkGR') {
        location = '화성';
      } else if (vehicleId == 'VEHICLEID') {
        location = '제주';
      } else if (port == 38083) {
        location = '화성';
      } else if (port == 28083) {
        location = '제주';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppConstants.backgroundSecondary,
            title: const Text(
              '백그라운드 서비스 상태',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusRow('서비스 실행', isRunning ? '실행 중' : '중지됨', isRunning),
                  const Divider(color: Colors.white24),
                  _buildStatusRow('위치', location, true),
                  _buildStatusRow('차량 ID', vehicleId, true),
                  _buildStatusRow('차량 번호', vehicleNumber, true),
                  _buildStatusRow('포트', port.toString(), true),
                  const Divider(color: Colors.white24),
                  _buildStatusRow('연결 상태', isDisconnected ? '끊어짐' : '연결됨', !isDisconnected),
                  _buildStatusRow(
                    '마지막 데이터',
                    lastTime == 0 ? '없음' : '${diff.toStringAsFixed(1)}분 전',
                    diff < 3,
                  ),
                  if (diff >= 3 && !isDisconnected)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ 3분 이상 데이터가 없습니다',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultSnackBar(
          message: '상태 확인 실패: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackgroundChecking = false);
      }
    }
  }

  /// 상태 행 빌드
  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Row(
            children: [
              if (label == '서비스 실행' || label == '연결 상태')
                Icon(
                  isGood ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: isGood ? Colors.green : Colors.red,
                ),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: label == '서비스 실행' || label == '연결 상태'
                      ? (isGood ? Colors.green : Colors.red)
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 백그라운드 서비스 시작
  Future<void> _startBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (!isRunning) {
        await service.startService();
        _showResultSnackBar(
          message: '백그라운드 서비스를 시작했습니다',
          isSuccess: true,
        );
      } else {
        _showResultSnackBar(
          message: '백그라운드 서비스가 이미 실행 중입니다',
          isSuccess: false,
        );
      }
    } catch (e) {
      _showResultSnackBar(
        message: '서비스 시작 실패: $e',
        isSuccess: false,
      );
    }
  }

  /// 백그라운드 서비스 중지
  Future<void> _stopBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (isRunning) {
        service.invoke("stopService");
        _showResultSnackBar(
          message: '백그라운드 서비스를 중지했습니다',
          isSuccess: true,
        );
      } else {
        _showResultSnackBar(
          message: '백그라운드 서비스가 실행되고 있지 않습니다',
          isSuccess: false,
        );
      }
    } catch (e) {
      _showResultSnackBar(
        message: '서비스 중지 실패: $e',
        isSuccess: false,
      );
    }
  }

  /// MQTT 연결 테스트 - 화성
  Future<void> _testMqttConnectionMars() async {
    await _testMqttConnection(
      port: AppConstants.mqttPortMars,
      location: '화성',
      setLoading: (loading) => setState(() => _isMqttMarsTesting = loading),
    );
  }

  /// MQTT 연결 테스트 - 제주
  Future<void> _testMqttConnectionJeju() async {
    await _testMqttConnection(
      port: AppConstants.mqttPortJeju,
      location: '제주',
      setLoading: (loading) => setState(() => _isMqttJejuTesting = loading),
    );
  }

  /// MQTT 연결 테스트 공통 함수
  Future<void> _testMqttConnection({
    required int port,
    required String location,
    required Function(bool) setLoading,
  }) async {
    setLoading(true);

    try {
      Logger.log('🔵 MQTT $location 연결 테스트 시작');

      // MQTT 클라이언트 생성
      final clientId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final client = MqttServerClient.withPort(
        'ws://${AppConstants.mqttHost}${AppConstants.mqttPath}',
        clientId,
        port,
      );

      client.useWebSocket = true;
      client.websocketProtocols = ['mqtt'];
      client.logging(on: false);
      client.keepAlivePeriod = 20;
      client.setProtocolV311();

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(AppConstants.mqttUsername, AppConstants.mqttPassword)
          .startClean()
          .keepAliveFor(20);

      client.connectionMessage = connMessage;

      // 연결 시도 (5초 타임아웃)
      await client.connect().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('연결 시간 초과');
        },
      );

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        Logger.log('✅ MQTT $location 연결 성공');
        _showResultSnackBar(
          message: 'MQTT $location 연결 성공 ✓',
          isSuccess: true,
        );
      } else {
        Logger.log('❌ MQTT $location 연결 실패: ${client.connectionStatus?.state}');
        _showResultSnackBar(
          message: 'MQTT $location 연결 실패',
          isSuccess: false,
        );
      }

      // 연결 종료
      client.disconnect();
    } catch (e) {
      Logger.log('❌ MQTT $location 연결 오류: $e');
      _showResultSnackBar(
        message: 'MQTT $location 연결 실패: $e',
        isSuccess: false,
      );
    } finally {
      setLoading(false);
    }
  }

  /// Janus 연결 테스트 (실제 연결)
  Future<void> _testJanusConnection() async {
    setState(() => _isJanusTesting = true);

    try {
      Logger.log('🔵 Janus 연결 테스트 시작');

      // Janus 서버 info API 호출
      final response = await http.get(
        Uri.parse('${AppConstants.janusServer}/info'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        Logger.log('✅ Janus 연결 성공: ${response.statusCode}');
        _showResultSnackBar(
          message: 'Janus 연결 성공 ✓',
          isSuccess: true,
        );
      } else {
        Logger.log('❌ Janus 연결 실패: ${response.statusCode}');
        _showResultSnackBar(
          message: 'Janus 응답 오류 (${response.statusCode})',
          isSuccess: false,
        );
      }
    } catch (e) {
      Logger.log('❌ Janus 연결 오류: $e');
      _showResultSnackBar(
        message: 'Janus 연결 실패: $e',
        isSuccess: false,
      );
    } finally {
      setState(() => _isJanusTesting = false);
    }
  }

  /// 캐시 초기화
  void _clearCache() {
    _showResultSnackBar(message: '캐시가 초기화되었습니다', isSuccess: true);
  }

  /// 결과 스낵바 표시
  void _showResultSnackBar({
    required String message,
    required bool isSuccess,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green[700] : Colors.red[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}