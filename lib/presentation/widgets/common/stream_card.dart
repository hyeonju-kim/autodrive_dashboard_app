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

  /// 재연결 콜백
  final VoidCallback onReconnect;

  const StreamCard({
    super.key,
    required this.title,
    required this.renderer,
    required this.isConnected,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
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
              // 비디오 스트림 또는 로딩 표시
              if (isConnected)
              // 연결된 경우 비디오 표시
                RTCVideoView(
                  renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              else
              // 연결 중인 경우 로딩 인디케이터
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
                          color: isConnected ? Colors.green : Colors.red,
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

              // 상단 우측: 새로고침 버튼
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
}