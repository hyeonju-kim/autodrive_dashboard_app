import 'package:flutter/material.dart';

/// 애플리케이션 전역 로깅 시스템
/// 디버깅과 모니터링을 위한 로그 메시지 관리
class Logger {
  /// 로그 메시지를 저장하는 내부 리스트
  static final List<String> _logs = [];

  /// 로그 변경 사항을 구독하는 리스너들
  static final List<VoidCallback> _listeners = [];

  /// 메모리 관리를 위한 최대 로그 개수
  static const int maxLogs = 100;

  /// 새로운 로그 메시지를 추가
  /// [message]: 로그로 기록할 메시지
  static void log(String message) {
    // 현재 시간을 HH:mm:ss 형식으로 포맷
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    // 시간 태그를 포함한 로그 메시지 생성
    final logMessage = '[$timeStr] $message';

    // 콘솔에 출력 (디버깅용)
    print(logMessage);

    // 로그 리스트에 추가
    _logs.add(logMessage);

    // 최대 개수를 초과하면 가장 오래된 로그 제거
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }

    // 모든 리스너에게 변경 사항 알림
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 읽기 전용 로그 리스트 반환
  /// 외부에서 로그 리스트를 직접 수정할 수 없도록 보호
  static List<String> get logs => List.unmodifiable(_logs);

  /// 모든 로그 삭제
  static void clear() {
    _logs.clear();
    // 리스너들에게 로그가 삭제되었음을 알림
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 로그 변경 사항을 구독할 리스너 추가
  /// UI가 로그 변경을 감지하고 업데이트할 수 있도록 함
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// 리스너 제거
  /// 메모리 누수 방지를 위해 사용하지 않는 리스너는 제거해야 함
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}