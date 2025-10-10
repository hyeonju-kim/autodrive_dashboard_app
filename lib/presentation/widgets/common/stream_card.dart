// lib/presentation/widgets/common/stream_card.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// 비디오 스트림을 표시하는 카드 위젯
/// WebRTC 비디오 스트림과 연결 상태를 시각화
class StreamCard extends StatelessWidget {
  /// 스트림 제목 (예: Stream 11, Stream 12)
  final String title;

  /// 비디오 렌더러
  final RTCVideoRenderer renderer;

  /// 연결 상태
  final bool isConnected;

  /// 운행 종료 상태 (추가)
  final bool isOperationEnded;

  /// 재연결 콜백 (제거해도 되지만 타입 호환성을 위해 유지)
  final VoidCallback? onReconnect;

  const StreamCard({
    super.key,
    required this.title,
    required this.renderer,
    required this.isConnected,
    this.isOperationEnded = false, // 기본값 false
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 215,
          color: Colors.black,
          child: Stack(
            children: [
              // 비디오 스트림 또는 상태 표시
              if (isConnected && !isOperationEnded)
                RTCVideoView(
                  renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: true, // ✅ 좌우 반전 추가
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 운행 종료일 때는 아이콘 없이, 연결 중일 때만 로딩 표시
                      if (!isOperationEnded)
                        const CircularProgressIndicator(color: Colors.blue),
                      if (!isOperationEnded)
                        const SizedBox(height: 12),
                      Text(
                        isOperationEnded ? '운행 종료' : '연결 중...',
                        style: TextStyle(
                          color: isOperationEnded ? Colors.grey : Colors.white70,
                          fontSize: isOperationEnded ? 14 : 14,
                          fontWeight: isOperationEnded ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

              // 상단 좌측: 스트림 정보 배지
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
                      // 연결 상태 표시 점
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 스트림 제목
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

              // 하단 우측: 전체화면 버튼 (운행 종료가 아니고 연결되어 있을 때만)
              if (isConnected && !isOperationEnded)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showFullScreen(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (isOperationEnded) {
      return Colors.grey;
    }
    return isConnected ? Colors.green : Colors.red;
  }

  /// 전체화면 표시
  void _showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenVideo(
          renderer: renderer,
          title: title,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

// FullScreenVideo 클래스는 동일하게 유지
class FullScreenVideo extends StatefulWidget {
  final RTCVideoRenderer renderer;
  final String title;

  const FullScreenVideo({
    super.key,
    required this.renderer,
    required this.title,
  });

  @override
  State<FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  @override
  void initState() {
    super.initState();
    // 전체화면 진입 시 가로모드로 전환
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 상태바 숨기기
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    // 전체화면 종료 시 원래 설정으로 복원
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 비디오 전체화면 표시
          Center(
            child: RTCVideoView(
              widget.renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              mirror: true, // 좌우 반전 추가
            ),
          ),

          // 상단 정보 및 닫기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 스트림 제목
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 닫기 버튼
                Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}