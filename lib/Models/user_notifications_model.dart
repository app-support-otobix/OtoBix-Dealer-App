import 'package:otobix/Models/car_model.dart';

class UserNotificationsModel {
  final String? id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  UserNotificationsModel({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory UserNotificationsModel.fromJson({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return UserNotificationsModel(
      id: documentId,
      userId: (data['userId'] ?? '').toString(),
      type: data['type'] ?? 'info',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      createdAt: parseMongoDbDate(data['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
