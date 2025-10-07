import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';

/// 대시보드의 로그 섹션
/// 시스템 로그를 표시하고 관리하는 위젯
class LogSection extends StatelessWidget {
  /// 로그 표시 여부
  final bool showLogs;

  /// 로그 닫기 콜백
  final VoidCallback onClose;

  const LogSection({
    super.key,
    required this.showLogs,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: showLogs ? 400 : 0,
      curve: Curves.easeInOut,
      child: showLogs
          ? Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.black87,
        child: Column(
          children: [
            // 헤더 영역
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // 터미널 아이콘
                  const Icon(Icons.terminal,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  // 제목
                  const Text(
                    '로그',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  // 로그 지우기 버튼
                  IconButton(
                    icon: const Icon(Icons.clear_all,
                        color: Colors.white70, size: 20),
                    onPressed: () => Logger.clear(),
                    tooltip: '로그 지우기',
                  ),
                  // 닫기 버튼
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 20),
                    onPressed: onClose,
                    tooltip: '닫기',
                  ),
                ],
              ),
            ),
            // 로그 리스트 영역
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  reverse: true, // 최신 로그가 하단에 표시
                  itemCount: Logger.logs.length,
                  itemBuilder: (context, index) {
                    // 역순 인덱스 계산 (최신 로그가 먼저)
                    final reversedIndex = Logger.logs.length - 1 - index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        Logger.logs[reversedIndex],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace', // 고정폭 폰트
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
    );
  }
}