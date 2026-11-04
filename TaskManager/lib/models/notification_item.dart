class NotificationItem {
  final String id;
  final String taskId;
  final String type;
  final String title;
  final String message;
  bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.taskId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'].toString(),
      taskId: json['taskId'].toString(),
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] == true,
      createdAt: DateTime.parse(json['createdAt'].toString()).toLocal(),
    );
  }
}