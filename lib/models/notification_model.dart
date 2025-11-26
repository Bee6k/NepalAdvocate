class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String? relatedId;
  final String? relatedType;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.relatedType,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user'] is String 
          ? json['user'] 
          : json['user']?['_id'] ?? json['user']?['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      relatedId: json['relatedId'],
      relatedType: json['relatedType'],
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

