import 'user_model.dart';

enum MessageType {
  text('text'),
  file('file'),
  system('system');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final UserModel? sender;
  final String content;
  final MessageType messageType;
  final String? fileUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.sender,
    required this.content,
    this.messageType = MessageType.text,
    this.fileUrl,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversation']?.toString() ?? json['conversationId'] ?? '',
      senderId: json['sender'] is String
          ? json['sender']
          : json['sender']?['_id'] ?? json['sender']?['id'] ?? '',
      sender: json['sender'] is Map
          ? UserModel.fromJson(json['sender'])
          : null,
      content: json['content'] ?? '',
      messageType: MessageType.fromString(json['messageType'] ?? 'text'),
      fileUrl: json['fileUrl'],
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'content': content,
      'messageType': messageType.value,
      'fileUrl': fileUrl,
    };
  }
}

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final List<UserModel>? participants;
  final String? appointmentId;
  final String? lastMessageId;
  final MessageModel? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.participantIds,
    this.participants,
    this.appointmentId,
    this.lastMessageId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['_id'] ?? json['id'] ?? '',
      participantIds: json['participants'] != null
          ? (json['participants'] as List<dynamic>)
              .map((p) {
                if (p is String) return p;
                final map = p as Map<String, dynamic>;
                return map['_id'] ?? map['id'] ?? '';
              })
              .cast<String>()
              .toList()
          : [],
      participants: json['participants'] != null
          ? (json['participants'] as List<dynamic>)
              .map((p) => p is Map<String, dynamic> ? UserModel.fromJson(p) : null)
              .whereType<UserModel>()
              .toList()
          : null,
      appointmentId: json['appointment']?.toString(),
      lastMessageId: json['lastMessage']?.toString(),
      lastMessage: json['lastMessage'] is Map<String, dynamic>
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

