import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_constants.dart';
import '../../widgets/dashboard/gauge_section.dart';
import '../../widgets/dashboard/turn_signal_section.dart';
import '../../widgets/dashboard/status_indicators_section.dart';
import '../../widgets/dashboard/log_section.dart';
import '../../widgets/common/stream_card.dart';
import 'dashboard_controller.dart';

/// 자율주행 관제 대시보드 메인 화면
/// Provider 패턴을 사용하여 상태 관리
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  /// 대시보드 컨트롤러
  late final DashboardController _controller;

  /// 방향등 깜빡임 애니메이션 컨트롤러
  late final AnimationController _blinkController;

  /// 스크롤 컨트롤러 (로그 자동 스크롤용)
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 컨트롤러 초기화
    _controller = DashboardController();
    _controller.init();

    // 깜빡임 애니메이션 설정 (0.5초 주기)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true); // 자동 반복

    // 로그 표시 상태 변경 시 스크롤 처리
    _controller.addListener(_handleLogVisibilityChange);
  }

  /// 로그 표시 상태 변경 처리
  /// 로그가 표시되면 최하단으로 자동 스크롤
  void _handleLogVisibilityChange() {
    if (_controller.showLogs) {
      // 애니메이션 완료 후 스크롤
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

  @override
  void dispose() {
    _controller.removeListener(_handleLogVisibilityChange);
    _controller.dispose();
    _blinkController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider를 사용하여 컨트롤러 제공
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundPrimary,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildFloatingActionBar(),
      ),
    );
  }

  /// 앱바 빌드
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<DashboardController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              // 메인 타이틀
              const Text(
                '자율주행 관제 대시보드',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              // 현재 시간
              Text(
                controller.currentTime,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
            ],
          );
        },
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppConstants.backgroundSecondary,
    );
  }

  /// 메인 바디 빌드
  Widget _buildBody() {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        // 차량 데이터 추출 (null safe)
        final vehicleData = controller.vehicleData;
        final speedKmh = vehicleData?.speedKmh ?? 0.0;
        final batteryPercent = vehicleData?.batteryGaugePercent ?? 0.0;

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: Colors.blue,
          backgroundColor: Colors.grey[800],
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 100, // FAB 공간 확보
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // 게이지 섹션
                    GaugeSection(
                      speedKmh: speedKmh,
                      batteryPercent: batteryPercent,
                    ),
                    const SizedBox(height: 20),

                    // 방향 지시등 섹션
                    TurnSignalSection(
                      turnSignal: vehicleData?.turnSignal ?? 0,
                      blinkAnimation: _blinkController,
                    ),
                    const SizedBox(height: 16),

                    // 상태 표시기 섹션
                    StatusIndicatorsSection(
                      isAutoDrive: vehicleData?.operationModeAuto ?? false,
                      isBraking: vehicleData?.brakePedal ?? false,
                      isBrushOn: vehicleData?.blowerRun ?? false,
                      harshDriving: vehicleData?.harshDriving ?? 0,
                    ),
                    const SizedBox(height: 20),

                    // 스트림 1 (전방 카메라)
                    StreamBuilder<bool>(
                      stream: controller.streamRepository.stream1.connectionStream,
                      initialData: false,
                      builder: (context, snapshot) {
                        return StreamCard(
                          title: 'Stream 11',
                          renderer: controller.streamRepository.stream1.renderer,
                          isConnected: snapshot.data ?? false,
                          onReconnect: controller.reconnectStream1,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 스트림 2 (측면 카메라)
                    StreamBuilder<bool>(
                      stream: controller.streamRepository.stream2.connectionStream,
                      initialData: false,
                      builder: (context, snapshot) {
                        return StreamCard(
                          title: 'Stream 12',
                          renderer: controller.streamRepository.stream2.renderer,
                          isConnected: snapshot.data ?? false,
                          onReconnect: controller.reconnectStream2,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // 로그 섹션
                    LogSection(
                      showLogs: controller.showLogs,
                      onClose: controller.toggleLogs,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 플로팅 액션 바 빌드
  /// 전체 연결 및 로그 토글 버튼
  Widget _buildFloatingActionBar() {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.backgroundSecondary,
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
              // 전체 연결 버튼
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.isRefreshing
                      ? null
                      : controller.connectAllStreams,
                  icon: controller.isRefreshing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.play_arrow, size: 18),
                  label: Text(controller.isRefreshing ? '연결 중...' : '전체 연결'),
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

              // 로그 토글 버튼
              ElevatedButton.icon(
                onPressed: controller.toggleLogs,
                icon: Icon(
                    controller.showLogs
                        ? Icons.keyboard_arrow_up
                        : Icons.terminal,
                    size: 18
                ),
                label: Text(controller.showLogs ? '닫기' : '로그'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}