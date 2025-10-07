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

  JanusService({required this.streamId});

  /// 비디오 렌더러 초기화
  /// UI에 비디오를 표시하기 전에 반드시 호출해야 함
  Future<void> initRenderer() async {
    await renderer.initialize();
  }

  /// Janus 서버에 연결하고 스트림 시청 시작
  /// 전체 연결 프로세스를 관리
  Future<void> connect() async {
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

      Logger.log('✅ 스트림 $streamId 연결 완료');
    } catch (e) {
      Logger.log('❌ 스트림 $streamId 연결 실패: $e');
      rethrow;
    }
  }

  /// Janus 세션 생성
  /// 모든 후속 요청에서 사용할 세션 ID를 받음
  Future<int> _createSession() async {
    final response = await http.post(
      Uri.parse(AppConstants.janusServer),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'janus': 'create', // 세션 생성 요청
        'transaction': _generateTransactionId(), // 고유 트랜잭션 ID
      }),
    ).timeout(const Duration(seconds: 10)); // 타임아웃 설정

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final id = data['data']['id'] as int;
      Logger.log('✅ 세션 생성: $id');
      return id;
    }
    throw Exception('세션 생성 실패');
  }

  /// Streaming 플러그인에 연결
  /// 생성된 세션에 플러그인을 붙여 미디어 스트림을 처리할 수 있게 함
  Future<int> _attachPlugin() async {
    final response = await http.post(
      Uri.parse('${AppConstants.janusServer}/$sessionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'janus': 'attach', // 플러그인 연결 요청
        'plugin': 'janus.plugin.streaming', // Streaming 플러그인 지정
        'transaction': _generateTransactionId(),
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final id = data['data']['id'] as int;
      Logger.log('✅ 플러그인 연결: $id');
      return id;
    }
    throw Exception('플러그인 연결 실패');
  }

  /// WebRTC 피어 연결 생성 및 설정
  /// ICE 서버 설정, 트랜시버 추가, 이벤트 핸들러 등록
  Future<RTCPeerConnection> _createPeerConnection() async {
    // ICE 서버 설정 (NAT 통과를 위해 필요)
    final configuration = {
      'iceServers': [
        // Google의 공개 STUN 서버
        {'urls': AppConstants.stunServers},
        // 자체 TURN 서버 (릴레이가 필요한 경우)
        {
          'urls': AppConstants.turnServer,
          'username': AppConstants.turnUsername,
          'credential': AppConstants.turnCredential,
        }
      ],
      'iceTransportPolicy': 'all', // 모든 ICE 후보 사용
      'sdpSemantics': 'unified-plan', // 최신 SDP 형식 사용
    };

    final pc = await createPeerConnection(configuration);

    // 비디오 수신용 트랜시버 추가 (수신 전용)
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    // ICE 후보 발견 시 Janus에 전송
    pc.onIceCandidate = _handleIceCandidate;

    // 미디어 트랙 수신 시 렌더러에 연결
    pc.onTrack = _handleTrack;

    // ICE 연결 상태 변경 모니터링
    pc.onIceConnectionState = _handleIceConnectionState;

    return pc;
  }

  /// ICE 후보 처리
  /// 로컬에서 발견된 ICE 후보를 Janus에 전송
  void _handleIceCandidate(RTCIceCandidate candidate) {
    if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
      _sendTrickle(candidate);
    }
  }

  /// 미디어 트랙 수신 처리
  /// Janus로부터 비디오 스트림을 받으면 렌더러에 연결
  void _handleTrack(RTCTrackEvent event) {
    if (event.track.kind == 'video' && event.streams.isNotEmpty) {
      Logger.log('🎥 스트림 $streamId 비디오 수신');
      renderer.srcObject = event.streams[0];
      isConnected = true;
      _connectionController.add(true);
    }
  }

  /// ICE 연결 상태 변경 처리
  /// 연결 실패나 끊김을 감지하여 UI에 알림
  void _handleIceConnectionState(RTCIceConnectionState state) {
    Logger.log('🔌 스트림 $streamId ICE: $state');

    // 연결 실패 또는 끊김 감지
    if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
        state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
      isConnected = false;
      _connectionController.add(false);
    }
  }

  /// 스트림 시청 요청
  /// Janus에 특정 스트림 ID의 비디오를 요청
  Future<void> _watchStream() async {
    await http.post(
      Uri.parse('${AppConstants.janusServer}/$sessionId/$handleId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'janus': 'message',
        'transaction': _generateTransactionId(),
        'body': {
          'request': 'watch', // 스트림 시청 요청
          'id': streamId, // 시청할 스트림 ID
        },
      }),
    ).timeout(const Duration(seconds: 10));
  }

  /// Janus 이벤트 폴링
  /// Long polling을 통해 Janus로부터 이벤트 수신
  Future<void> pollEvents() async {
    if (sessionId == null) return;

    try {
      // maxev=1: 한 번에 하나의 이벤트만 수신
      final response = await http
          .get(Uri.parse('${AppConstants.janusServer}/$sessionId?maxev=1'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data is List ? data : [data];

        // 수신된 모든 이벤트 처리
        for (final event in events) {
          await _handleJanusEvent(event);
        }
      }
    } catch (e) {
      // 폴링 에러는 치명적이지 않으므로 조용히 처리
      // 네트워크 일시적 오류일 수 있음
    }
  }

  /// Janus 이벤트 처리
  /// JSEP offer가 포함된 이벤트 처리
  Future<void> _handleJanusEvent(Map<String, dynamic> event) async {
    // JSEP offer가 포함된 경우 처리
    if (event['jsep'] != null && event['jsep']['type'] == 'offer') {
      await _handleOffer(event['jsep']);
    }
  }

  /// SDP Offer 처리 및 Answer 생성
  /// Janus로부터 받은 offer에 대한 answer를 생성하고 전송
  Future<void> _handleOffer(Map<String, dynamic> jsep) async {
    try {
      // 원격 SDP 설정
      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(jsep['sdp'], jsep['type']),
      );

      // Answer 생성
      final answer = await peerConnection!.createAnswer({});

      // H.264 코덱 강제 활성화 및 DTLS setup 조정
      String modifiedSdp = SdpHelper.forceEnableH264(answer.sdp!);
      modifiedSdp = SdpHelper.ensurePassiveSetup(modifiedSdp);

      // 수정된 Answer를 로컬 SDP로 설정
      final modifiedAnswer = RTCSessionDescription(modifiedSdp, answer.type);
      await peerConnection!.setLocalDescription(modifiedAnswer);

      // Janus에 Answer 전송과 함께 스트림 시작 요청
      await http.post(
        Uri.parse('${AppConstants.janusServer}/$sessionId/$handleId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'janus': 'message',
          'transaction': _generateTransactionId(),
          'body': {'request': 'start'}, // 스트림 시작 요청
          'jsep': {
            'type': modifiedAnswer.type,
            'sdp': modifiedAnswer.sdp,
          },
        }),
      );
    } catch (e) {
      Logger.log('❌ Offer 처리 실패: $e');
    }
  }

  /// ICE 후보를 Janus에 전송 (Trickle ICE)
  /// 점진적으로 발견되는 ICE 후보를 실시간으로 전송
  Future<void> _sendTrickle(RTCIceCandidate candidate) async {
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
      // Trickle 실패는 치명적이지 않음
      // 다른 ICE 후보로 연결 가능
    }
  }

  /// 고유한 트랜잭션 ID 생성
  /// 요청-응답 매칭을 위해 사용
  String _generateTransactionId() {
    return 'tx_${DateTime.now().millisecondsSinceEpoch}_$streamId';
  }

  /// 리소스 정리
  /// 렌더러, 피어 연결, 스트림 컨트롤러 해제
  void dispose() {
    renderer.dispose();
    peerConnection?.close();
    _connectionController.close();
  }
}