import 'dart:async';
import '../services/janus_service.dart';
import '../../core/config/app_constants.dart';
import '../../core/utils/logger.dart';

/// 스트림 관련 비즈니스 로직을 관리하는 리포지토리
/// 여러 JanusService 인스턴스를 조정하고 폴링을 관리
class StreamRepository {
  /// 첫 번째 스트림 서비스 (전방 카메라)
  final JanusService _stream1Service = JanusService(streamId: AppConstants.stream1Id);

  /// 두 번째 스트림 서비스 (측면 카메라)
  final JanusService _stream2Service = JanusService(streamId: AppConstants.stream2Id);

  /// Janus 이벤트 폴링 타이머
  Timer? _pollTimer;

  /// 스트림 서비스 게터 (UI에서 접근용)
  JanusService get stream1 => _stream1Service;
  JanusService get stream2 => _stream2Service;

  /// 모든 스트림 서비스 초기화
  /// 비디오 렌더러들을 초기화
  Future<void> init() async {
    await _stream1Service.initRenderer();
    await _stream2Service.initRenderer();
  }

  /// 모든 스트림에 동시 연결
  /// 병렬 처리로 연결 시간 단축
  Future<void> connectAll() async {
    try {
      Logger.log('=== 양쪽 스트림 연결 시작 ===');

      // Future.wait로 두 스트림을 동시에 연결
      await Future.wait([
        _stream1Service.connect(),
        _stream2Service.connect(),
      ]);

      // 연결 성공 후 폴링 시작
      _startPolling();
    } catch (e) {
      Logger.log('❌ 스트림 연결 실패: $e');
      rethrow;
    }
  }

  /// 첫 번째 스트림만 연결
  Future<void> connectStream1() async {
    await _stream1Service.connect();
  }

  /// 두 번째 스트림만 연결
  Future<void> connectStream2() async {
    await _stream2Service.connect();
  }

  /// Janus 이벤트 폴링 시작
  /// 주기적으로 서버에서 이벤트를 가져옴
  void _startPolling() {
    // 기존 타이머가 있으면 취소
    _pollTimer?.cancel();

    // 500ms마다 폴링 실행
    _pollTimer = Timer.periodic(AppConstants.pollInterval, (timer) {
      _pollEvents();
    });
  }

  /// 모든 스트림의 이벤트를 폴링
  /// 병렬로 처리하여 효율성 향상
  Future<void> _pollEvents() async {
    await Future.wait([
      _stream1Service.pollEvents(),
      _stream2Service.pollEvents(),
    ]);
  }

  /// 모든 스트림 연결 해제
  /// 폴링 중단 및 WebRTC 연결 종료
  void disconnect() {
    _pollTimer?.cancel();
    _stream1Service.peerConnection?.close();
    _stream2Service.peerConnection?.close();
  }

  /// 리소스 정리
  /// 메모리 누수 방지를 위해 모든 리소스 해제
  void dispose() {
    _pollTimer?.cancel();
    _stream1Service.dispose();
    _stream2Service.dispose();
  }
}