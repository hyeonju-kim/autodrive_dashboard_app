import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_constants.dart';
import '../../widgets/dashboard/gauge_section.dart';
import '../../widgets/dashboard/log_section.dart';
import '../../widgets/common/stream_card.dart';
import '../../widgets/dashboard/vehicle_status_section.dart';
import 'dashboard_controller.dart';

/// 자율주행 관제 대시보드 메인 화면
/// Provider 패턴을 사용하여 상태 관리
class DashboardScreen extends StatefulWidget {
  final bool isMars; // true: 화성, false: 제주
  const DashboardScreen({super.key, this.isMars = true}); // 기본값: 화성

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

    // 지역별 컨트롤러 생성
    _controller = DashboardController(isMars: widget.isMars);
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
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundPrimary,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBody(),
          ],
        ),
      ),
    );
  }

  /// 앱바 빌드
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<DashboardController>(
        builder: (context, controller, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.isMars ? Icons.home_work : Icons.landscape,
                color: controller.isMars ? Colors.orange : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                '자율주행 관제 대시보드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: controller.isMars
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: controller.isMars
                        ? Colors.orange.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  controller.isMars ? '화성' : '제주',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: controller.isMars ? Colors.orange : Colors.blue,
                  ),
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


  Widget _buildBody() {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        final vehicleData = controller.vehicleData;
        final speedKmh = vehicleData?.speedKmh ?? 0.0;
        final batteryPercent = vehicleData?.batteryGaugePercent ?? 0.0;

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: Colors.blue,
          backgroundColor: Colors.grey[800],
          child: Column(
            children: [
              // 차량 정보 섹션
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundSecondary.withOpacity(0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${controller.vehicleNumber} (${controller.vehicleId})',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
              // 나머지 콘텐츠
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 80,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // 게이지 섹션
                    GaugeSection(
                      speedKmh: speedKmh,
                      batteryPercent: batteryPercent,
                    ),
                    const SizedBox(height: 8),

                    // 통합된 차량 상태 섹션
                    VehicleStatusSection(
                      turnSignal: vehicleData?.turnSignal ?? 0,
                      blinkAnimation: _blinkController,
                      isAutoDrive: vehicleData?.operationModeAuto ?? false,
                      isBraking: vehicleData?.brakePedal ?? false,
                      isBrushOn: vehicleData?.blowerRun ?? false,
                      harshDriving: vehicleData?.harshDriving ?? 0,
                    ),
                    const SizedBox(height: 8),

                    // 스트림 1
                    StreamBuilder<bool>(
                      stream: controller.stream1.connectionStream,
                      initialData: false,
                      builder: (context, snapshot) {
                        return StreamCard(
                          title: 'Stream ${controller.stream1Id}',
                          renderer: controller.stream1.renderer,
                          isConnected: snapshot.data ?? false,
                          isOperationEnded: controller.isOperationEnded, // 운행 종료 상태 전달

                        );
                      },
                    ),
                    const SizedBox(height: 6),

                    // 스트림 2
                    StreamBuilder<bool>(
                      stream: controller.stream2.connectionStream,
                      initialData: false,
                      builder: (context, snapshot) {
                        return StreamCard(
                          title: 'Stream ${controller.stream2Id}',
                          renderer: controller.stream2.renderer,
                          isConnected: snapshot.data ?? false,
                          isOperationEnded: controller.isOperationEnded, // 운행 종료 상태 전달

                        );
                      },
                    ),
                    const SizedBox(height: 16),


                    // 로그 버튼 (작고 눈에 안 띄게)
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: controller.toggleLogs,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(
                            Icons.more_horiz,
                            size: 16,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),

                    // 로그 섹션
                    if (controller.showLogs) ...[
                      const SizedBox(height: 8),
                      LogSection(
                        showLogs: controller.showLogs,
                        onClose: controller.toggleLogs,
                      ),
                    ],

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

}