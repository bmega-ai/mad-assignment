class NotificationItem {
  final int id;
  final String title;
  final String message;
  bool isRead;
  final String createdAtFormatted;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAtFormatted,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAtFormatted: json['created_at_formatted'] ?? json['created_at'] ?? '',
    );
  }
}
