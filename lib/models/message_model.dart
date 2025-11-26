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
    try {
      // Handle different date formats
      DateTime parseDate(dynamic dateValue) {
        if (dateValue == null) return DateTime.now();
        if (dateValue is DateTime) return dateValue;
        if (dateValue is String) {
          try {
            return DateTime.parse(dateValue);
          } catch (e) {
            return DateTime.now();
          }
        }
        return DateTime.now();
      }

      // Extract conversation ID
      String conversationId = '';
      if (json['conversation'] != null) {
        if (json['conversation'] is String) {
          conversationId = json['conversation'];
        } else if (json['conversation'] is Map) {
          conversationId = json['conversation']['_id']?.toString() ?? json['conversation']['id']?.toString() ?? '';
        }
      }
      conversationId = conversationId.isEmpty ? (json['conversationId']?.toString() ?? '') : conversationId;

      // Extract sender ID - prioritize senderId field, then extract from sender object
      String senderId = '';
      if (json['senderId'] != null) {
        senderId = json['senderId'].toString();
      } else if (json['sender'] != null) {
        if (json['sender'] is String) {
          senderId = json['sender'].toString();
        } else if (json['sender'] is Map) {
          senderId = json['sender']['_id']?.toString() ?? 
                     json['sender']['id']?.toString() ?? 
                     '';
        }
      }

      return MessageModel(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        conversationId: conversationId,
        senderId: senderId,
        sender: json['sender'] is Map<String, dynamic>
            ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
            : null,
        content: (json['content'] ?? '').toString(),
        messageType: MessageType.fromString(json['messageType']?.toString() ?? 'text'),
        fileUrl: json['fileUrl']?.toString(),
        isRead: json['isRead'] == true || json['isRead'] == 'true',
        readAt: json['readAt'] != null ? parseDate(json['readAt']) : null,
        createdAt: parseDate(json['createdAt']),
      );
    } catch (e) {
      print('Error parsing MessageModel: $e');
      print('JSON data: $json');
      rethrow;
    }
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

