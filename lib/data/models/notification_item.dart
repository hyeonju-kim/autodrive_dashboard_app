// lib/data/models/notification_item.dart

/// 알림 메시지 객체
class NotificationItem {
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      title: json['title'],
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}
