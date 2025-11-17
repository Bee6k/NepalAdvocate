import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants/api_constants.dart';
import '../core/utils/storage_service.dart';
import '../core/utils/api_client.dart';
import '../models/message_model.dart';

class ChatService {
  IO.Socket? _socket;
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected ?? false) return;

    final token = await _storage.getToken();
    if (token == null) throw Exception('No authentication token');

    _socket = IO.io(
      ApiConstants.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void joinConversation(String conversationId) {
    _socket?.emit('joinConversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leaveConversation', conversationId);
  }

  void sendMessage({
    required String conversationId,
    required String content,
    MessageType messageType = MessageType.text,
    String? fileUrl,
  }) {
    _socket?.emit('sendMessage', {
      'conversationId': conversationId,
      'content': content,
      'messageType': messageType.value,
      'fileUrl': fileUrl,
    });
  }

  void onMessage(Function(MessageModel) callback) {
    _socket?.on('newMessage', (data) {
      if (data['message'] != null) {
        callback(MessageModel.fromJson(data['message']));
      }
    });
  }

  void onTyping(Function(String userId, bool isTyping) callback) {
    _socket?.on('userTyping', (data) {
      callback(data['userId'], data['isTyping'] ?? false);
    });
  }

  void onNotification(Function(Map<String, dynamic>) callback) {
    _socket?.on('notification', (data) {
      callback(data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data));
    });
  }

  void onError(Function(String) callback) {
    _socket?.on('error', (data) {
      callback(data['message'] ?? 'An error occurred');
    });
  }

  void onConnect(Function() callback) {
    _socket?.on('connect', (_) => callback());
  }

  void onDisconnect(Function() callback) {
    _socket?.on('disconnect', (_) => callback());
  }

  void sendTyping(String conversationId, bool isTyping) {
    _socket?.emit('typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _apiClient.get(ApiConstants.conversations);
      if (response.data['success'] == true) {
        final conversations = response.data['data']['conversations'] as List;
        return conversations.map((json) => ConversationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.messages}/$conversationId/messages',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final messages = response.data['data']['messages'] as List;
        return messages.map((json) => MessageModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

