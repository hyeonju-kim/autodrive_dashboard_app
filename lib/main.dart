import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Janus Streaming',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const JanusStreamingPage(),
    );
  }
}

class JanusStreamingPage extends StatefulWidget {
  const JanusStreamingPage({super.key});

  @override
  State<JanusStreamingPage> createState() => _JanusStreamingPageState();
}

class _JanusStreamingPageState extends State<JanusStreamingPage> with TickerProviderStateMixin {
  static const String janusServer = 'http://123.143.232.180:25800/janus';

  // Stream 11 관련
  int? _sessionId1;
  int? _handleId1;
  RTCPeerConnection? _peerConnection1;
  final RTCVideoRenderer _remoteRenderer1 = RTCVideoRenderer();
  bool _isConnected1 = false;

  // Stream 12 관련
  int? _sessionId2;
  int? _handleId2;
  RTCPeerConnection? _peerConnection2;
  final RTCVideoRenderer _remoteRenderer2 = RTCVideoRenderer();
  bool _isConnected2 = false;

  Timer? _pollTimer;
  Timer? _clockTimer;
  final List<String> _logs = [];
  bool _showLogs = false;
  String _currentTime = '';
  bool _isRefreshing = false;

  final ScrollController _scrollController = ScrollController();

  // MQTT 관련
  MqttClient? _mqttClient;
  double _currentSpeed = 0.0;
  double _batteryPercent = 0.0;
  bool _isMqttConnected = false;
  int _turnSignal = 0; // 0=Off, 1=Right, 2=Left, 3=비상등

  // 상태 표시 관련
  bool _isAutoDrive = false;
  bool _isBraking = false;
  bool _isBrushOn = false;
  int _harshDriving = 0; // 0: 정상, 1: 급가속, -1: 급감속

  // 애니메이션
  AnimationController? _blinkController;

  @override
  void initState() {
    super.initState();
    log('🚀 앱 초기화 시작');

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _initRenderers();
    _startClock();
    _connectMqtt();
  }

  Future<void> _connectMqtt() async {
    print('🚀 MQTT 연결 시작');

    try {
      final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
      log('🆔 Client ID: $clientId');

      _mqttClient = MqttServerClient.withPort('ws://192.168.2.51/mqtt', clientId, 8083);
      (_mqttClient as MqttServerClient).useWebSocket = true;
      (_mqttClient as MqttServerClient).websocketProtocols = ['mqtt'];

      log('✅ 클라이언트 생성');

      _mqttClient!.logging(on: false);
      _mqttClient!.keepAlivePeriod = 60;
      _mqttClient!.autoReconnect = true;
      _mqttClient!.setProtocolV311();

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs('socket', 'thzpt!@#')
          .startClean()
          .keepAliveFor(60);

      _mqttClient!.connectionMessage = connMessage;

      print('🔄 연결: ws://192.168.2.51:8083/mqtt');
      await _mqttClient!.connect();

      if (_mqttClient!.connectionStatus!.state == MqttConnectionState.connected) {
        print('✅ MQTT 연결 성공!');
        log('✅ MQTT 연결 성공');

        setState(() => _isMqttConnected = true);

        _mqttClient!.subscribe('/topic/f4FwwkGR', MqttQos.atLeastOnce);
        log('✅ 토픽 구독 완료');

        _mqttClient!.updates!.listen((messages) {
          final recMess = messages[0].payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

          try {
            final data = jsonDecode(payload);
            if (data['inVehicleData'] != null) {
              setState(() {
                _currentSpeed = (data['inVehicleData']['speedXMps'] ?? 0.0).toDouble();
                _batteryPercent = (data['inVehicleData']['batteryGaugePercent'] ?? 0.0).toDouble();
                _turnSignal = (data['inVehicleData']['turnSignal'] ?? 0) as int;

                // 브레이크
                _isBraking = data['inVehicleData']['brakePedal'] ?? false;

                // 급가속/급감속 - 양수면 급가속, 음수면 급감속
                double accelX = (data['inVehicleData']['accelerationXMps2'] ?? 0.0).toDouble();
                if (accelX > 0) {
                  _harshDriving = 1; // 급가속
                } else if (accelX < 0) {
                  _harshDriving = -1; // 급감속
                } else {
                  _harshDriving = 0; // 정상
                }
              });
            }

            // 자율주행
            if (data['operationStatusData'] != null) {
              setState(() {
                _isAutoDrive = data['operationStatusData']['operationMode'] == 'DRIVE_AUTO';
              });
            }

            // 브러쉬
            if (data['serviceModuleData'] != null) {
              setState(() {
                _isBrushOn = data['serviceModuleData']['blowerRun'] ?? false;
              });
            }

          } catch (e) {
            print('파싱 오류: $e');
          }
        });
      }
    } catch (e) {
      print('오류: $e');
      log('❌ MQTT 오류: $e');
    }
  }

  void _startClock() {
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      });
    }
  }

  Future<void> _initRenderers() async {
    log('🎬 비디오 렌더러 초기화 중...');
    await _remoteRenderer1.initialize();
    await _remoteRenderer2.initialize();
    log('✅ 비디오 렌더러 초기화 완료');
  }

  void log(String message) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    final logMessage = '[$timeStr] $message';
    print(logMessage);

    if (mounted) {
      setState(() {
        _logs.add(logMessage);
        if (_logs.length > 100) {
          _logs.removeAt(0);
        }
      });
    }
  }

  void _toggleLogs() {
    setState(() {
      _showLogs = !_showLogs;
    });

    if (_showLogs) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    log('🔄 새로고침 시작');

    _pollTimer?.cancel();
    _peerConnection1?.close();
    _peerConnection2?.close();

    setState(() {
      _sessionId1 = null;
      _handleId1 = null;
      _sessionId2 = null;
      _handleId2 = null;
      _isConnected1 = false;
      _isConnected2 = false;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    await connectBothStreams();

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> connectBothStreams() async {
    try {
      log('=== 양쪽 스트림 연결 시작 ===');
      await Future.wait([
        connectToJanus(11, isFirstStream: true),
        connectToJanus(12, isFirstStream: false),
      ]);
      _startPolling();
    } catch (e) {
      log('❌ 연결 실패: $e');
    }
  }

  Future<void> connectToJanus(int streamId, {required bool isFirstStream}) async {
    try {
      log('🔌 스트림 $streamId 연결 시작');

      final sessionId = await _createSession();
      final handleId = await _attachPlugin(sessionId);
      final pc = await _createPeerConnection(streamId, isFirstStream);
      await _watchStream(sessionId, handleId, streamId);

      if (isFirstStream) {
        _sessionId1 = sessionId;
        _handleId1 = handleId;
        _peerConnection1 = pc;
      } else {
        _sessionId2 = sessionId;
        _handleId2 = handleId;
        _peerConnection2 = pc;
      }
    } catch (e) {
      log('❌ 스트림 $streamId 연결 실패: $e');
    }
  }

  Future<int> _createSession() async {
    final response = await http
        .post(
      Uri.parse(janusServer),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'janus': 'create',
        'transaction': _generateTransactionId(),
      }),
    )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final sessionId = data['data']['id'] as int;
      log('✅ 세션 생성: $sessionId');
      return sessionId;
    }
    throw Exception('세션 생성 실패');
  }

  Future<int> _attachPlugin(int sessionId) async {
    final response = await http.post(
      Uri.parse('$janusServer/$sessionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'janus': 'attach',
        'plugin': 'janus.plugin.streaming',
        'transaction': _generateTransactionId(),
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final handleId = data['data']['id'] as int;
      log('✅ 플러그인 연결: $handleId');
      return handleId;
    }
    throw Exception('플러그인 연결 실패');
  }

  Future<RTCPeerConnection> _createPeerConnection(int streamId, bool isFirstStream) async {
    final configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
            'stun:stun1.l.google.com:19302',
          ]
        },
        {
          'urls': 'turn:123.143.232.180:3478',
          'username': 'platform',
          'credential': 'Abacus0131!',
        }
      ],
      'iceTransportPolicy': 'all',
      'sdpSemantics': 'unified-plan',
    };

    final pc = await createPeerConnection(configuration);

    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        _sendTrickle(
          isFirstStream ? _sessionId1! : _sessionId2!,
          isFirstStream ? _handleId1! : _handleId2!,
          candidate,
        );
      }
    };

    pc.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        log('🎥 스트림 $streamId 비디오 수신');
        if (mounted) {
          setState(() {
            if (isFirstStream) {
              _remoteRenderer1.srcObject = event.streams[0];
              _isConnected1 = true;
            } else {
              _remoteRenderer2.srcObject = event.streams[0];
              _isConnected2 = true;
            }
          });
        }
      }
    };

    pc.onIceConnectionState = (RTCIceConnectionState state) {
      log('🔌 스트림 $streamId ICE: $state');
    };

    return pc;
  }

  Future<void> _watchStream(int sessionId, int handleId, int streamId) async {
    await http.post(
      Uri.parse('$janusServer/$sessionId/$handleId'),
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
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _pollEvents();
    });
  }

  Future<void> _pollEvents() async {
    if (_sessionId1 != null) {
      await _pollSession(_sessionId1!, _handleId1!, true);
    }
    if (_sessionId2 != null) {
      await _pollSession(_sessionId2!, _handleId2!, false);
    }
  }

  Future<void> _pollSession(int sessionId, int handleId, bool isFirstStream) async {
    try {
      final response = await http
          .get(Uri.parse('$janusServer/$sessionId?maxev=1'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data is List ? data : [data];

        for (final event in events) {
          await _handleJanusEvent(event, sessionId, handleId, isFirstStream);
        }
      }
    } catch (e) {
      // 폴링 에러는 조용히 처리
    }
  }

  Future<void> _handleJanusEvent(
      Map<String, dynamic> event, int sessionId, int handleId, bool isFirstStream) async {
    if (event['jsep'] != null && event['jsep']['type'] == 'offer') {
      await _handleOffer(event['jsep'], sessionId, handleId, isFirstStream);
    }
  }

  Future<void> _handleOffer(
      Map<String, dynamic> jsep, int sessionId, int handleId, bool isFirstStream) async {
    try {
      final pc = isFirstStream ? _peerConnection1! : _peerConnection2!;

      await pc.setRemoteDescription(
        RTCSessionDescription(jsep['sdp'], jsep['type']),
      );

      final answer = await pc.createAnswer({});
      String modifiedSdp = _forceEnableH264(answer.sdp!);

      if (!modifiedSdp.contains('a=setup:')) {
        modifiedSdp = modifiedSdp.replaceFirst(
          'a=mid:',
          'a=setup:passive\r\na=mid:',
        );
      } else {
        modifiedSdp = modifiedSdp.replaceAll('a=setup:active', 'a=setup:passive');
        modifiedSdp = modifiedSdp.replaceAll('a=setup:actpass', 'a=setup:passive');
      }

      final modifiedAnswer = RTCSessionDescription(modifiedSdp, answer.type);
      await pc.setLocalDescription(modifiedAnswer);

      await http.post(
        Uri.parse('$janusServer/$sessionId/$handleId'),
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
      );
    } catch (e) {
      log('❌ Offer 처리 실패: $e');
    }
  }

  String _forceEnableH264(String sdp) {
    final lines = sdp.split('\r\n');
    final mLineIndex = lines.indexWhere((l) => l.startsWith('m=video'));
    if (mLineIndex == -1) return sdp;

    lines[mLineIndex] = 'm=video 9 UDP/TLS/RTP/SAVPF 96';
    if (!lines.any((l) => l.contains('a=rtpmap:96 H264/90000'))) {
      lines.insert(mLineIndex + 1, 'a=rtpmap:96 H264/90000');
      lines.insert(mLineIndex + 2, 'a=rtcp-fb:96 nack pli');
      lines.insert(mLineIndex + 3, 'a=fmtp:96 profile-level-id=42e01f;packetization-mode=1');
    }
    return lines.join('\r\n');
  }

  Future<void> _sendTrickle(int sessionId, int handleId, RTCIceCandidate candidate) async {
    try {
      await http.post(
        Uri.parse('$janusServer/$sessionId/$handleId'),
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
    }
  }

  String _generateTransactionId() {
    return 'tx_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _blinkController?.dispose();
    _scrollController.dispose();
    _remoteRenderer1.dispose();
    _remoteRenderer2.dispose();
    _peerConnection1?.close();
    _peerConnection2?.close();
    _mqttClient?.disconnect();
    super.dispose();
  }

  Widget _buildGauge({
    required String label,
    required String value,
    required String unit,
    required double percentage,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(140, 140),
            painter: GaugePainter(
              percentage: percentage,
              color: color,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnSignalIndicator() {
    return AnimatedBuilder(
      animation: _blinkController!,
      builder: (context, child) {
        double opacity = 1.0;

        if (_turnSignal != 0) {
          opacity = 0.3 + (_blinkController!.value * 0.7);
        }

        Color leftColor = Colors.grey.withOpacity(0.3);
        Color rightColor = Colors.grey.withOpacity(0.3);
        Color emergencyColor = Colors.grey.withOpacity(0.3);

        String leftText = '좌방향등';
        String rightText = '우방향등';
        Color leftTextColor = Colors.grey.withOpacity(0.5);
        Color rightTextColor = Colors.grey.withOpacity(0.5);

        if (_turnSignal == 1) {
          rightColor = Colors.amber.withOpacity(opacity);
          rightTextColor = Colors.amber.withOpacity(opacity);
        } else if (_turnSignal == 2) {
          leftColor = Colors.amber.withOpacity(opacity);
          leftTextColor = Colors.amber.withOpacity(opacity);
        } else if (_turnSignal == 3) {
          emergencyColor = Colors.red.withOpacity(opacity);
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0d1419),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 36,
                      color: leftColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leftText,
                      style: TextStyle(
                        fontSize: 10,
                        color: leftTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: emergencyColor,
                  shape: BoxShape.circle,
                  boxShadow: _turnSignal == 3
                      ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(opacity * 0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ]
                      : [],
                ),
                child: Icon(
                  Icons.warning,
                  size: 28,
                  color: _turnSignal == 3 ? Colors.white : Colors.grey[700],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 36,
                      color: rightColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rightText,
                      style: TextStyle(
                        fontSize: 10,
                        color: rightTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1419),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusButton(
            icon: Icons.directions_car,
            label: '자율주행',
            isOn: _isAutoDrive,
            onColor: Colors.blue,
          ),
          _buildStatusButton(
            icon: Icons.local_parking,
            label: '브레이크',
            isOn: _isBraking,
            onColor: Colors.grey[600]!,
          ),
          _buildStatusButton(
            icon: Icons.cleaning_services,
            label: '브러쉬',
            isOn: _isBrushOn,
            onColor: Colors.grey[600]!,
          ),
          _buildHarshDrivingButton(),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required IconData icon,
    required String label,
    required bool isOn,
    required Color onColor,
  }) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isOn ? onColor : Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHarshDrivingButton() {
    bool isAccel = _harshDriving > 0;
    bool isDecel = _harshDriving < 0;

    Color alertColor;
    String alertText;

    if (isAccel) {
      alertColor = Colors.orange;
      alertText = '급가속';
    } else if (isDecel) {
      alertColor = Colors.red;
      alertText = '급정거';
    } else {
      alertColor = Colors.grey[800]!;
      alertText = '';
    }

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: alertColor,
              shape: BoxShape.circle,
            ),
            child: alertText.isNotEmpty
                ? Center(
              child: Text(
                alertText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
                : Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '급가속/급정거',
            style: TextStyle(
              fontSize: 8,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamCard(
      String title, RTCVideoRenderer renderer, bool isConnected, VoidCallback onReconnect) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 220,
          color: Colors.black,
          child: Stack(
            children: [
              if (isConnected)
                RTCVideoView(
                  renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              else
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.blue),
                      SizedBox(height: 12),
                      Text(
                        '연결 중...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isConnected ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  onPressed: onReconnect,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final speedKmh = _currentSpeed;

    return Scaffold(
      backgroundColor: const Color(0xFF1a2332),
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              '자율주행 관제 대시보드',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              _currentTime,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF0d1419),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.blue,
        backgroundColor: Colors.grey[800],
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // 게이지 영역
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0d1419),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGauge(
                          label: 'SPEED',
                          value: speedKmh.toStringAsFixed(0),
                          unit: 'KM/H',
                          percentage: (speedKmh / 50).clamp(0.0, 1.0),
                          color: Colors.cyan,
                          icon: Icons.speed,
                        ),
                        _buildGauge(
                          label: 'BATTERY',
                          value: _batteryPercent.toStringAsFixed(0),
                          unit: '%',
                          percentage: _batteryPercent / 100,
                          color: Colors.green,
                          icon: Icons.battery_charging_full,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 턴시그널 표시
                  _buildTurnSignalIndicator(),

                  const SizedBox(height: 16),

                  // 상태 표시
                  _buildStatusIndicators(),

                  const SizedBox(height: 20),

                  // 스트림 11
                  _buildStreamCard(
                    'Stream 11',
                    _remoteRenderer1,
                    _isConnected1,
                        () => connectToJanus(11, isFirstStream: true),
                  ),
                  const SizedBox(height: 16),

                  // 스트림 12
                  _buildStreamCard(
                    'Stream 12',
                    _remoteRenderer2,
                    _isConnected2,
                        () => connectToJanus(12, isFirstStream: false),
                  ),
                  const SizedBox(height: 20),

                  // 로그 섹션
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showLogs ? 400 : 0,
                    curve: Curves.easeInOut,
                    child: _showLogs
                        ? Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.black87,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.terminal, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  '로그',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.clear_all, color: Colors.white70, size: 20),
                                  onPressed: () => setState(() => _logs.clear()),
                                  tooltip: '로그 지우기',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _showLogs = false;
                                    });
                                  },
                                  tooltip: '닫기',
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: ListView.builder(
                                reverse: true,
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  final reversedIndex = _logs.length - 1 - index;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      _logs[reversedIndex],
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0d1419),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRefreshing ? null : connectBothStreams,
                icon: _isRefreshing
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.play_arrow, size: 18),
                label: Text(_isRefreshing ? '연결 중...' : '전체 연결'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _toggleLogs,
              icon: Icon(_showLogs ? Icons.keyboard_arrow_up : Icons.terminal, size: 18),
              label: Text(_showLogs ? '닫기' : '로그'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 게이지 페인터
class GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - 10, backgroundPaint);

    for (int i = 0; i < 40; i++) {
      final angle = (-math.pi * 0.75) + (math.pi * 1.5 * i / 40);
      final x1 = center.dx + (radius - 20) * math.cos(angle);
      final y1 = center.dy + (radius - 20) * math.sin(angle);
      final x2 = center.dx + (radius - 12) * math.cos(angle);
      final y2 = center.dy + (radius - 12) * math.sin(angle);

      final tickPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 1.5;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * 1.5 * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi * 0.75,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}