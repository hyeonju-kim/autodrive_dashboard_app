import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/sdp_helper.dart';

/// Janus WebRTC 게이트웨이와의 통신을 관리하는 서비스
/// 비디오 스트림 연결, 시그널링, ICE 협상 처리
class JanusService {
  /// Janus 세션 ID
  int? sessionId;

  /// Streaming 플러그인 핸들 ID
  int? handleId;

  /// WebRTC 피어 연결 객체
  RTCPeerConnection? peerConnection;

  /// 비디오 렌더러 (UI에 비디오를 표시하기 위한 객체)
  final RTCVideoRenderer renderer = RTCVideoRenderer();

  /// 스트림 연결 상태
  bool isConnected = false;

  /// 이 서비스가 관리하는 스트림 ID
  final int streamId;

  /// 연결 상태 변경을 알리는 스트림 컨트롤러
  final _connectionController = StreamController<bool>.broadcast();

  /// 연결 상태 스트림 (UI에서 구독)
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Keep-alive 타이머
  Timer? _keepAliveTimer;

  /// 폴링 타이머
  Timer? _pollTimer;

  /// 재연결 시도 횟수
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  /// 재연결 중인지 여부
  bool _isReconnecting = false;

  /// 연결 중인지 여부
  bool _isConnecting = false;

  JanusService({required this.streamId});

  /// 비디오 렌더러 초기화
  /// UI에 비디오를 표시하기 전에 반드시 호출해야 함
  Future<void> initRenderer() async {
    await renderer.initialize();
  }

  /// Janus 서버에 연결하고 스트림 시청 시작
  /// 전체 연결 프로세스를 관리
  Future<void> connect() async {
    // 이미 연결 중이면 무시
    if (_isConnecting || _isReconnecting) {
      Logger.log('⚠️ 이미 연결 중입니다');
      return;
    }

    _isConnecting = true;

    try {
      Logger.log('🔌 스트림 $streamId 연결 시작');

      // 1. Janus 세션 생성
      sessionId = await _createSession();

      // 2. Streaming 플러그인 연결
      handleId = await _attachPlugin();

      // 3. WebRTC 피어 연결 생성
      peerConnection = await _createPeerConnection();

      // 4. 스트림 시청 요청
      await _watchStream();

      // 5. Keep-alive 시작
      _startKeepAlive();

      // 6. 이벤트 폴링 시작
      _startPolling();

      _reconnectAttempts = 0; // 성공 시 재연결 시도 횟수 초기화
      _isConnecting = false;

      Logger.log('✅ 스트림 $streamId 연결 완료');
    } catch (e) {
      _isConnecting = false;
      Logger.log('❌ 스트림 $streamId 연결 실패: $e');

      // 연결 실패 시 재연결 시도
      if (_reconnectAttempts < _maxReconnectAttempts) {
        await _scheduleReconnect();
      } else {
        rethrow;
      }
    }
  }

  /// Janus 세션 생성
  /// 모든 후속 요청에서 사용할 세션 ID를 받음
  Future<int> _createSession() async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.janusServer),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'janus': 'create',
          'transaction': _generateTransactionId(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 에러 체크
        if (data['janus'] == 'error') {
          throw Exception('Janus error: ${data['error']['reason']}');
        }

        final id = data['data']['id'] as int;
        Logger.log('✅ 세션 생성: $id');
        return id;
      }
      throw Exception('세션 생성 실패: ${response.statusCode}');
    } catch (e) {
      Logger.log('❌ 세션 생성 에러: $e');
      rethrow;
    }
  }

  /// Streaming 플러그인에 연결
  Future<int> _attachPlugin() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.janusServer}/$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'janus': 'attach',
          'plugin': 'janus.plugin.streaming',
          'transaction': _generateTransactionId(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 세션 만료 체크
        if (_isSessionExpiredError(data)) {
          Logger.log('⚠️ 세션 만료 감지 - 재연결 필요');
          throw Exception('Session expired');
        }

        final id = data['data']['id'] as int;
        Logger.log('✅ 플러그인 연결: $id');
        return id;
      }
      throw Exception('플러그인 연결 실패: ${response.statusCode}');
    } catch (e) {
      Logger.log('❌ 플러그인 연결 에러: $e');
      rethrow;
    }
  }

  /// WebRTC 피어 연결 생성 및 설정
  Future<RTCPeerConnection> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': AppConstants.stunServers},
        {
          'urls': AppConstants.turnServer,
          'username': AppConstants.turnUsername,
          'credential': AppConstants.turnCredential,
        }
      ],
      'iceTransportPolicy': 'all',
      'sdpSemantics': 'unified-plan',
    };

    final pc = await createPeerConnection(configuration);

    // 비디오 수신용 트랜시버 추가
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    // 이벤트 핸들러 등록
    pc.onIceCandidate = _handleIceCandidate;
    pc.onTrack = _handleTrack;
    pc.onIceConnectionState = _handleIceConnectionState;
    pc.onConnectionState = _handleConnectionState;

    return pc;
  }

  /// 연결 상태 처리
  void _handleConnectionState(RTCPeerConnectionState state) {
    Logger.log('🔌 스트림 $streamId 연결 상태: $state');

    if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      Logger.log('⚠️ 피어 연결 실패 - 재연결 시도');
      _scheduleReconnect();
    }
  }

  /// ICE 후보 처리
  void _handleIceCandidate(RTCIceCandidate candidate) {
    if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
      _sendTrickle(candidate);
    }
  }

  /// 미디어 트랙 수신 처리
  void _handleTrack(RTCTrackEvent event) {
    if (event.track.kind == 'video' && event.streams.isNotEmpty) {
      Logger.log('🎥 스트림 $streamId 비디오 수신');
      renderer.srcObject = event.streams[0];
      isConnected = true;
      _connectionController.add(true);
    }
  }

  /// ICE 연결 상태 변경 처리
  void _handleIceConnectionState(RTCIceConnectionState state) {
    Logger.log('🔌 스트림 $streamId ICE: $state');

    if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
        state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
      isConnected = false;
      _connectionController.add(false);

      // ICE 실패 시 재연결 시도
      if (!_isReconnecting) {
        _scheduleReconnect();
      }
    } else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
      isConnected = true;
      _connectionController.add(true);
      _reconnectAttempts = 0; // 연결 성공 시 시도 횟수 초기화
    }
  }

  /// 스트림 시청 요청
  Future<void> _watchStream() async {
    final response = await http.post(
      Uri.parse('${AppConstants.janusServer}/$sessionId/$handleId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'janus': 'message',
        'transaction': _generateTransactionId(),
        'body': {
          'request': 'watch',
          'id': streamId,
        },
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('스트림 시청 요청 실패');
    }
  }

  /// Keep-alive 시작
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      _sendKeepAlive();
    });
  }

  /// 이벤트 폴링 시작
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      pollEvents();
    });
  }

  /// Keep-alive 전송
  Future<void> _sendKeepAlive() async {
    if (sessionId == null) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.janusServer}/$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'janus': 'keepalive',
          'transaction': _generateTransactionId(),
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 정상 응답 확인
        if (data['janus'] == 'ack') {
          // Keep-alive 성공
          return;
        }

        // 세션 만료 체크
        if (_isSessionExpiredError(data)) {
          Logger.log('⚠️ Keep-alive 중 세션 만료 감지');
          await reconnect();
        }
      }
    } catch (e) {
      Logger.log('❌ Keep-alive 실패: $e');
      await reconnect();
    }
  }

  /// 세션 만료 에러 체크
  bool _isSessionExpiredError(Map<String, dynamic> data) {
    if (data['janus'] == 'error') {
      final reason = data['error']?['reason']?.toString() ?? '';
      final code = data['error']?['code'] ?? 0;

      return reason.toLowerCase().contains('session') ||
          reason.toLowerCase().contains('not found') ||
          code == 458; // JANUS_ERROR_SESSION_NOT_FOUND
    }
    return false;
  }

  /// Janus 이벤트 폴링
  Future<void> pollEvents() async {
    if (sessionId == null || _isReconnecting || _isConnecting) return;

    try {
      final response = await http
          .get(Uri.parse('${AppConstants.janusServer}/$sessionId?maxev=1'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 세션 만료 체크
        if (_isSessionExpiredError(data)) {
          Logger.log('⚠️ 폴링 중 세션 만료 감지');
          await reconnect();
          return;
        }

        final events = data is List ? data : [data];
        for (final event in events) {
          await _handleJanusEvent(event);
        }
      } else if (response.statusCode == 404) {
        // 404는 세션이 없다는 의미
        Logger.log('⚠️ 세션이 존재하지 않음 (404)');
        await reconnect();
      }
    } catch (e) {
      // 연결 관련 에러만 재연결
      if (e.toString().contains('404') ||
          e.toString().contains('session') ||
          e.toString().contains('SocketException')) {
        await reconnect();
      }
    }
  }

  /// Janus 이벤트 처리
  Future<void> _handleJanusEvent(Map<String, dynamic> event) async {
    if (event['jsep'] != null && event['jsep']['type'] == 'offer') {
      await _handleOffer(event['jsep']);
    }

    // 플러그인 이벤트 처리
    if (event['plugindata'] != null) {
      final data = event['plugindata']['data'];
      if (data != null && data['streaming'] == 'event') {
        final result = data['result'];
        if (result != null && result['status'] == 'stopped') {
          Logger.log('⚠️ 스트림이 중지됨');
          _scheduleReconnect();
        }
      }
    }
  }

  /// SDP Offer 처리 및 Answer 생성
  Future<void> _handleOffer(Map<String, dynamic> jsep) async {
    try {
      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(jsep['sdp'], jsep['type']),
      );

      final answer = await peerConnection!.createAnswer({});

      // H.264 코덱 강제 활성화 및 DTLS setup 조정
      String modifiedSdp = SdpHelper.forceEnableH264(answer.sdp!);
      modifiedSdp = SdpHelper.ensurePassiveSetup(modifiedSdp);

      final modifiedAnswer = RTCSessionDescription(modifiedSdp, answer.type);
      await peerConnection!.setLocalDescription(modifiedAnswer);

      // Janus에 Answer 전송
      final response = await http.post(
        Uri.parse('${AppConstants.janusServer}/$sessionId/$handleId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'janus': 'message',
          'transaction': _generateTransactionId(),
          'body': {'request': 'start'},
          'jsep': {
            'type': modifiedAnswer.type,
            'sdp': modifiedAnswer.sdp,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Logger.log('✅ Answer 전송 완료');
      }
    } catch (e) {
      Logger.log('❌ Offer 처리 실패: $e');
    }
  }

  /// ICE 후보를 Janus에 전송
  Future<void> _sendTrickle(RTCIceCandidate candidate) async {
    if (sessionId == null || handleId == null) return;

    try {
      await http.post(
        Uri.parse('${AppConstants.janusServer}/$sessionId/$handleId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'janus': 'trickle',
          'transaction': _generateTransactionId(),
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        }),
      );
    } catch (e) {
      // Trickle 실패는 무시
    }
  }

  /// 재연결 스케줄링
  Future<void> _scheduleReconnect() async {
    if (_isReconnecting || _isConnecting) return;

    _reconnectAttempts++;
    if (_reconnectAttempts > _maxReconnectAttempts) {
      Logger.log('❌ 최대 재연결 시도 횟수 초과');
      _connectionController.add(false);
      return;
    }

    final delay = Duration(seconds: _reconnectAttempts * 2); // 지수 백오프
    Logger.log('⏱️ ${delay.inSeconds}초 후 재연결 시도 (${_reconnectAttempts}/$_maxReconnectAttempts)');

    await Future.delayed(delay);
    await reconnect();
  }

  /// 재연결
  Future<void> reconnect() async {
    if (_isReconnecting || _isConnecting) return;

    _isReconnecting = true;
    Logger.log('🔄 스트림 $streamId 재연결 시도...');

    try {
      // 기존 연결 정리
      await _cleanup(destroy: true);

      // 잠시 대기
      await Future.delayed(const Duration(seconds: 1));

      // 재연결
      await connect();

      _isReconnecting = false;
    } catch (e) {
      _isReconnecting = false;
      Logger.log('❌ 재연결 실패: $e');

      // 재연결 실패 시 다시 스케줄링
      if (_reconnectAttempts < _maxReconnectAttempts) {
        await _scheduleReconnect();
      }
    }
  }

  /// 세션 종료
  Future<void> _destroySession() async {
    if (sessionId == null) return;

    try {
      await http.post(
        Uri.parse('${AppConstants.janusServer}/$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'janus': 'destroy',
          'transaction': _generateTransactionId(),
        }),
      ).timeout(const Duration(seconds: 2));

      Logger.log('✅ 세션 종료 완료');
    } catch (e) {
      // 무시 - 세션이 이미 만료되었을 수 있음
    }
  }

  /// 고유한 트랜잭션 ID 생성
  String _generateTransactionId() {
    return 'tx_${DateTime.now().millisecondsSinceEpoch}_${streamId}_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// 연결 정리 (내부용)
  Future<void> _cleanup({bool destroy = false}) async {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;

    _pollTimer?.cancel();
    _pollTimer = null;

    if (peerConnection != null) {
      await peerConnection!.close();
      peerConnection = null;
    }

    if (destroy && sessionId != null) {
      await _destroySession();
    }

    sessionId = null;
    handleId = null;

    isConnected = false;
    _connectionController.add(false);
  }

  /// 연결 끊기 (외부 호출용)
  Future<void> disconnect() async {
    Logger.log('🔌 Stream $streamId 연결 종료');
    _reconnectAttempts = _maxReconnectAttempts + 1; // 재연결 방지
    await _cleanup(destroy: true);
  }

  /// 리소스 정리
  Future<void> dispose() async {
    await disconnect();
    await renderer.dispose();
    await _connectionController.close();
  }
}