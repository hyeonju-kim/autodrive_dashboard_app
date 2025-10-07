/// SDP(Session Description Protocol) 처리를 위한 유틸리티 클래스
/// WebRTC 연결 설정 시 미디어 코덱과 연결 방식을 조정
class SdpHelper {
  /// SDP에서 H.264 비디오 코덱을 강제로 활성화
  /// 일부 브라우저나 장치에서 호환성 문제를 해결하기 위해 사용
  /// [sdp]: 수정할 SDP 문자열
  /// 반환값: H.264가 활성화된 수정된 SDP
  static String forceEnableH264(String sdp) {
    // SDP를 줄 단위로 분리
    final lines = sdp.split('\r\n');

    // 비디오 미디어 라인 찾기
    final mLineIndex = lines.indexWhere((l) => l.startsWith('m=video'));
    if (mLineIndex == -1) return sdp; // 비디오가 없으면 원본 반환

    // 비디오 미디어 라인을 H.264(페이로드 타입 96) 사용으로 변경
    lines[mLineIndex] = 'm=video 9 UDP/TLS/RTP/SAVPF 96';

    // H.264 코덱 정보가 없으면 추가
    if (!lines.any((l) => l.contains('a=rtpmap:96 H264/90000'))) {
      // RTP 맵핑 정보 추가 (페이로드 타입 96을 H.264로 매핑)
      lines.insert(mLineIndex + 1, 'a=rtpmap:96 H264/90000');

      // RTCP 피드백 메커니즘 설정 (NACK, PLI 지원)
      lines.insert(mLineIndex + 2, 'a=rtcp-fb:96 nack pli');

      // H.264 프로파일 설정 (Baseline Profile, Level 3.1)
      lines.insert(mLineIndex + 3, 'a=fmtp:96 profile-level-id=42e01f;packetization-mode=1');
    }

    // 수정된 라인들을 다시 합쳐서 반환
    return lines.join('\r\n');
  }

  /// SDP의 DTLS setup 속성을 passive로 설정
  /// Janus 서버와의 DTLS 협상 시 클라이언트가 passive 역할을 하도록 함
  /// [sdp]: 수정할 SDP 문자열
  /// 반환값: setup이 passive로 설정된 SDP
  static String ensurePassiveSetup(String sdp) {
    // setup 속성이 없으면 추가
    if (!sdp.contains('a=setup:')) {
      // mid 속성 앞에 setup:passive 추가
      return sdp.replaceFirst(
        'a=mid:',
        'a=setup:passive\r\na=mid:',
      );
    } else {
      // 기존 setup 속성을 passive로 변경
      return sdp
          .replaceAll('a=setup:active', 'a=setup:passive')
          .replaceAll('a=setup:actpass', 'a=setup:passive');
    }
  }
}