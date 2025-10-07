import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/vehicle_data.dart';
import '../../../data/services/mqtt_service.dart';
import '../../../data/repositories/stream_repository.dart';

/// 대시보드 화면의 비즈니스 로직을 관리하는 컨트롤러
/// ChangeNotifier를 상속받아 UI에 상태 변경을 알림
class DashboardController extends ChangeNotifier {
  // ===== 서비스 및 리포지토리 =====
  /// MQTT 서비스 인스턴스
  final MqttService _mqttService = MqttService();

  /// 스트림 리포지토리 인스턴스
  final StreamRepository _streamRepository = StreamRepository();

  // ===== 타이머 =====
  /// 시계 업데이트 타이머
  Timer? _clockTimer;

  // ===== 상태 변수 =====
  /// 현재 시간 문자열
  String _currentTime = '';

  /// 새로고침 진행 중 여부
  bool _isRefreshing = false;

  /// 로그 표시 여부
  bool _showLogs = false;

  /// 현재 차량 데이터
  VehicleData? _vehicleData;

  /// MQTT 연결 상태
  bool _isMqttConnected = false;

  // ===== 구독 =====
  /// MQTT 차량 데이터 구독
  StreamSubscription<VehicleData>? _vehicleDataSubscription;

  /// MQTT 연결 상태 구독
  StreamSubscription<bool>? _mqttConnectionSubscription;

  /// 로그 변경 리스너
  VoidCallback? _logListener;

  // ===== Getters =====
  /// 현재 시간
  String get currentTime => _currentTime;

  /// 새로고침 상태
  bool get isRefreshing => _isRefreshing;

  /// 로그 표시 상태
  bool get showLogs => _showLogs;

  /// 차량 데이터
  VehicleData? get vehicleData => _vehicleData;

  /// MQTT 연결 상태
  bool get isMqttConnected => _isMqttConnected;

  /// 스트림 리포지토리 (UI에서 직접 접근용)
  StreamRepository get streamRepository => _streamRepository;

  /// 컨트롤러 초기화
  /// 서비스들을 초기화하고 연결을 시작
  Future<void> init() async {
    Logger.log('🚀 대시보드 컨트롤러 초기화 시작');

    // 비디오 렌더러 초기화
    await _streamRepository.init();

    // 시계 시작
    _startClock();

    // MQTT 연결
    await _connectMqtt();

    // 로그 리스너 등록
    _logListener = () => notifyListeners();
    Logger.addListener(_logListener!);

    // 자동으로 모든 스트림 연결
    await connectAllStreams();
  }

  /// 시계 시작
  /// 매초마다 현재 시간을 업데이트
  void _startClock() {
    _updateTime();
    _clockTimer = Timer.periodic(AppConstants.clockUpdateInterval, (timer) {
      _updateTime();
    });
  }

  /// 현재 시간 업데이트
  void _updateTime() {
    _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    notifyListeners();
  }

  /// MQTT 서비스 연결
  /// 차량 데이터 스트림을 구독하고 상태 업데이트
  Future<void> _connectMqtt() async {
    try {
      // MQTT 연결
      await _mqttService.connect();

      // 차량 데이터 스트림 구독
      _vehicleDataSubscription = _mqttService.vehicleDataStream.listen(
            (data) {
          _vehicleData = data;
          notifyListeners();
        },
      );

      // 연결 상태 스트림 구독
      _mqttConnectionSubscription = _mqttService.connectionStream.listen(
            (connected) {
          _isMqttConnected = connected;
          notifyListeners();
        },
      );
    } catch (e) {
      Logger.log('❌ MQTT 연결 실패: $e');
    }
  }

  /// 모든 스트림 연결
  /// 두 카메라 스트림을 동시에 연결
  Future<void> connectAllStreams() async {
    await _streamRepository.connectAll();
  }

  /// 첫 번째 스트림 재연결
  Future<void> reconnectStream1() async {
    await _streamRepository.connectStream1();
  }

  /// 두 번째 스트림 재연결
  Future<void> reconnectStream2() async {
    await _streamRepository.connectStream2();
  }

  /// 전체 새로고침
  /// 모든 연결을 재시작
  Future<void> refresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    Logger.log('🔄 새로고침 시작');

    // 기존 연결 해제
    _streamRepository.disconnect();

    // 잠시 대기 (연결 정리를 위해)
    await Future.delayed(const Duration(milliseconds: 500));

    // 재연결
    await connectAllStreams();

    _isRefreshing = false;
    notifyListeners();
  }

  /// 로그 표시 토글
  void toggleLogs() {
    _showLogs = !_showLogs;
    notifyListeners();
  }

  /// 리소스 정리
  /// 모든 타이머, 구독, 서비스를 정리
  @override
  void dispose() {
    Logger.log('🛑 대시보드 컨트롤러 종료');

    // 타이머 정리
    _clockTimer?.cancel();

    // 구독 정리
    _vehicleDataSubscription?.cancel();
    _mqttConnectionSubscription?.cancel();

    // 로그 리스너 제거
    if (_logListener != null) {
      Logger.removeListener(_logListener!);
    }

    // 서비스 정리
    _mqttService.dispose();
    _streamRepository.dispose();

    super.dispose();
  }
}