class NotificationModel {
  final String id;
  final String sentBy;
  final String fileName;
  final String status;
  final DateTime createdAt;
  final bool read;
  final String senderName;

  NotificationModel({
    required this.id,
    required this.sentBy,
    required this.fileName,
    required this.status,
    required this.createdAt,
    required this.read,
    required this.senderName,
  });
}