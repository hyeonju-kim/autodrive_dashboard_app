// lib/presentation/screens/dashboard/dashboard_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/vehicle_data.dart';
import '../../../data/services/mqtt_service.dart';
import '../../../data/services/janus_service.dart';

/// 대시보드 화면의 비즈니스 로직을 관리하는 컨트롤러
/// 화성/제주 둘 다 사용 가능
class DashboardController extends ChangeNotifier {
  // ===== 지역 구분 =====
  final bool isMars; // true: 화성, false: 제주

  // ===== 서비스 =====
  final MqttService _mqttService = MqttService();
  late final JanusService _stream1Service;
  late final JanusService _stream2Service;

  Timer? _pollTimer;
  Timer? _clockTimer;

  // ===== 상태 변수 =====
  String _currentTime = '';
  bool _isRefreshing = false;
  bool _showLogs = false;
  VehicleData? _vehicleData;
  bool _isMqttConnected = false;

  // ===== 구독 =====
  StreamSubscription<VehicleData>? _vehicleDataSubscription;
  StreamSubscription<bool>? _mqttConnectionSubscription;
  VoidCallback? _logListener;

  // ===== Getters =====
  String get currentTime => _currentTime;
  bool get isRefreshing => _isRefreshing;
  bool get showLogs => _showLogs;
  VehicleData? get vehicleData => _vehicleData;
  bool get isMqttConnected => _isMqttConnected;

  // 지역별 정보
  String get vehicleNumber => isMars ? AppConstants.marsVehicleNumber : AppConstants.jejuVehicleNumber;
  String get vehicleId => isMars ? AppConstants.marsVehicleId : AppConstants.jejuVehicleId;
  String get mqttTopic => isMars ? AppConstants.mqttTopicMars : AppConstants.mqttTopicJeju;
  int get stream1Id => isMars ? AppConstants.stream1Id : AppConstants.jejuStream1Id;
  int get stream2Id => isMars ? AppConstants.stream2Id : AppConstants.jejuStream2Id;

  JanusService get stream1 => _stream1Service;
  JanusService get stream2 => _stream2Service;

  DashboardController({required this.isMars}) {
    // 지역별 스트림 ID로 JanusService 초기화
    _stream1Service = JanusService(streamId: stream1Id);
    _stream2Service = JanusService(streamId: stream2Id);
  }

  /// 컨트롤러 초기화
  Future<void> init() async {
    Logger.log('🚀 ${isMars ? "화성" : "제주"} 대시보드 컨트롤러 초기화 시작');

    // 비디오 렌더러 초기화
    await _stream1Service.initRenderer();
    await _stream2Service.initRenderer();

    _startClock();
    await _connectMqtt();

    _logListener = () => notifyListeners();
    Logger.addListener(_logListener!);

    // 자동으로 모든 스트림 연결
    await connectAllStreams();
  }

  void _startClock() {
    _updateTime();
    _clockTimer = Timer.periodic(AppConstants.clockUpdateInterval, (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    notifyListeners();
  }

  Future<void> _connectMqtt() async {
    try {
      await _mqttService.connectToTopic(mqttTopic);

      _vehicleDataSubscription = _mqttService.vehicleDataStream.listen(
            (data) {
          _vehicleData = data;
          notifyListeners();
        },
      );

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

  Future<void> connectAllStreams() async {
    try {
      Logger.log('=== ${isMars ? "화성" : "제주"} 스트림 연결 시작 ===');
      await Future.wait([
        _stream1Service.connect(),
        _stream2Service.connect(),
      ]);
      _startPolling();
    } catch (e) {
      Logger.log('❌ 스트림 연결 실패: $e');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(AppConstants.pollInterval, (timer) {
      _pollEvents();
    });
  }

  Future<void> _pollEvents() async {
    await Future.wait([
      _stream1Service.pollEvents(),
      _stream2Service.pollEvents(),
    ]);
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    Logger.log('🔄 새로고침 시작');

    _pollTimer?.cancel();
    _stream1Service.peerConnection?.close();
    _stream2Service.peerConnection?.close();

    await Future.delayed(const Duration(milliseconds: 500));
    await connectAllStreams();

    _isRefreshing = false;
    notifyListeners();
  }

  void toggleLogs() {
    _showLogs = !_showLogs;
    notifyListeners();
  }

  @override
  void dispose() {
    Logger.log('🛑 ${isMars ? "화성" : "제주"} 대시보드 컨트롤러 종료');

    _clockTimer?.cancel();
    _pollTimer?.cancel();
    _vehicleDataSubscription?.cancel();
    _mqttConnectionSubscription?.cancel();

    if (_logListener != null) {
      Logger.removeListener(_logListener!);
    }

    _mqttService.dispose();
    _stream1Service.dispose();
    _stream2Service.dispose();

    super.dispose();
  }
}