import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:dio/dio.dart';
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
    if (token == null) {
      print('ChatService: No authentication token available');
      throw Exception('No authentication token');
    }

    try {
      _socket = IO.io(
        ApiConstants.wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      _socket!.on('connect', (_) {
        print('ChatService: Socket connected');
      });

      _socket!.on('disconnect', (_) {
        print('ChatService: Socket disconnected');
      });

      _socket!.on('connect_error', (error) {
        print('ChatService: Connection error: $error');
      });

      _socket!.connect();
    } catch (e) {
      print('ChatService: Error connecting: $e');
      rethrow;
    }
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
    if (_socket == null || !_socket!.connected) {
      print('ChatService: Socket not connected, cannot send message');
      throw Exception('Socket not connected');
    }
    
    print('ChatService: Sending message - conversationId: $conversationId, content: $content, messageType: ${messageType.value}, fileUrl: $fileUrl');
    
    _socket!.emit('sendMessage', {
      'conversationId': conversationId,
      'content': content,
      'messageType': messageType.value,
      'fileUrl': fileUrl,
    });
  }

  void onMessage(Function(MessageModel) callback) {
    _socket?.on('newMessage', (data) {
      try {
        print('ChatService: Received new message: $data');
        if (data != null) {
          Map<String, dynamic> messageData;
          if (data is Map<String, dynamic>) {
            messageData = data['message'] ?? data;
          } else {
            messageData = Map<String, dynamic>.from(data);
            if (messageData.containsKey('message')) {
              messageData = Map<String, dynamic>.from(messageData['message']);
            }
          }
          if (messageData.isNotEmpty) {
            callback(MessageModel.fromJson(messageData));
          }
        }
      } catch (e) {
        print('ChatService: Error parsing message: $e');
        print('ChatService: Message data: $data');
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

  Future<ConversationModel> getOrCreateConversation(String userId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.findConversation}/$userId');
      if (response.data['success'] == true) {
        return ConversationModel.fromJson(response.data['data']['conversation']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get conversation');
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
      
      throw Exception(response.data['message'] ?? 'Failed to load messages');
    } on DioException catch (e) {
      // Handle DioException (network/HTTP errors)
      if (e.response?.statusCode == 403) {
        final errorData = e.response?.data;
        if (errorData is Map && 
            (errorData['error'] == 'APPOINTMENT_NOT_CONFIRMED' || 
             errorData['message']?.toString().toLowerCase().contains('appointment') == true)) {
          throw Exception('Chat is only available after the appointment is confirmed by the lawyer');
        }
        throw Exception(errorData?['message'] ?? 'Access denied');
      }
      rethrow;
    } catch (e) {
      // Re-throw with better error message if it mentions appointment
      if (e.toString().toLowerCase().contains('appointment') || 
          e.toString().contains('403')) {
        throw Exception('Chat is only available after the appointment is confirmed by the lawyer');
      }
      rethrow;
    }
  }
}

