// lib/presentation/screens/notifications/notification_list_screen.dart

/// 알림 저장소
import 'package:flutter/material.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/models/notification_item.dart';
import '../../../core/config/app_constants.dart';
import 'package:intl/intl.dart';

import '../../../data/services/notification_service.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final list = await NotificationRepository.getAllNotifications();
    setState(() => _notifications = list);
  }

  Future<void> _markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    await NotificationRepository.saveAll(_notifications);
  }

  @override
  void dispose() {
    _markAllAsRead();
    NotificationService.notifyStateChanged(); // ✅ 복귀 시 Main 화면 리빌드 유도
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          '알림 목록',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        // title: const Text('알림 목록', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.backgroundSecondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white70),
            onPressed: () async {
              await NotificationRepository.clearAll();
              setState(() => _notifications.clear());
            },
          ),
        ],
      ),
      // ✅ RefreshIndicator 추가
      body: RefreshIndicator(
        color: Colors.blueAccent, // 새로고침 로딩 인디케이터 색상
        backgroundColor: AppConstants.backgroundSecondary, // 배경색
        displacement: 30, // 얼마나 아래로 당겨야 트리거되는지(px)
        onRefresh: _loadNotifications, // 새로고침 로직 연결

        child: _notifications.isEmpty
            ? const Center(
          child: Text(
            '아직 받은 알림이 없습니다.',
            style: TextStyle(color: Colors.white54),
          ),
        )
            : ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(), // 비어 있어도 당김 가능하게
          itemCount: _notifications.length,
          separatorBuilder: (_, __) => Divider(
            color: Colors.white12,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final item = _notifications[index];
            final time =
            DateFormat('MM/dd HH:mm:ss').format(item.timestamp);
            return ListTile(
              title: Text(item.title,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(item.body,
                  style: TextStyle(color: Colors.white70)),
              trailing: Text(
                time,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
              ),
            );
          },
        ),
      ),
    );
  }
}
