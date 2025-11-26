import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

// Import ConversationModel from message_model.dart
// (ConversationModel is defined in the same file as MessageModel)

class ChatController extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final ChatService _chatService;
  final String conversationId;

  ChatController(this._chatService, this.conversationId) : super(const AsyncValue.loading()) {
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Ensure socket is connected
      if (!_chatService.isConnected) {
        await _chatService.connect();
      }
      
      // Join conversation room
      _chatService.joinConversation(conversationId);
      
      // Setup listeners before loading messages
      _setupListeners();
      
      // Load existing messages
      await loadMessages();
    } catch (e) {
      print('ChatController: Error initializing: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _setupListeners() {
    _chatService.onMessage((message) {
      print('ChatController: Received message for conversation ${message.conversationId}, current: $conversationId');
      print('ChatController: Message senderId: ${message.senderId}, message ID: ${message.id}');
      
      // Check if message belongs to this conversation
      final messageConvId = message.conversationId?.toString() ?? '';
      final currentConvId = conversationId.toString();
      
      if (messageConvId == currentConvId) {
        final currentMessages = state.value ?? [];
        // Check if message already exists to avoid duplicates
        final messageExists = currentMessages.any((m) => 
          m.id == message.id || 
          (m.content == message.content && 
           m.senderId.toString() == message.senderId.toString() &&
           (m.createdAt.difference(message.createdAt).inSeconds.abs() < 2))
        );
        
        if (!messageExists) {
          print('ChatController: Adding new message to list');
          state = AsyncValue.data([...currentMessages, message]);
        } else {
          print('ChatController: Message already exists, skipping');
        }
      }
    });
  }

  Future<void> loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _chatService.getMessages(conversationId);
      state = AsyncValue.data(messages);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendMessage(String content, {String? fileUrl}) async {
    try {
      // Ensure socket is connected
      if (!_chatService.isConnected) {
        print('ChatController: Socket not connected, connecting...');
        await _chatService.connect();
        // Wait a bit for connection to establish
        await Future.delayed(const Duration(milliseconds: 500));
        _chatService.joinConversation(conversationId);
      }
      
      // Verify connection before sending
      if (!_chatService.isConnected) {
        throw Exception('Failed to establish socket connection');
      }
      
      print('ChatController: Sending message - content: $content, fileUrl: $fileUrl');
      
      // Don't add optimistic message - wait for real message from socket
      // This prevents duplicate messages
      _chatService.sendMessage(
        conversationId: conversationId,
        content: content,
        messageType: fileUrl != null ? MessageType.file : MessageType.text,
        fileUrl: fileUrl,
      );
      
      print('ChatController: Message sent successfully');
    } catch (e) {
      print('ChatController: Error sending message: $e');
      rethrow;
    }
  }

  void sendTyping(bool isTyping) {
    _chatService.sendTyping(conversationId, isTyping);
  }

  @override
  void dispose() {
    _chatService.leaveConversation(conversationId);
    super.dispose();
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  final service = ChatService();
  service.connect();
  ref.onDispose(() => service.disconnect());
  return service;
});

final chatControllerProvider = StateNotifierProvider.family<
    ChatController, AsyncValue<List<MessageModel>>, String>((ref, conversationId) {
  return ChatController(ref.read(chatServiceProvider), conversationId);
});

final conversationsProvider = FutureProvider<List<ConversationModel>>((ref) async {
  final chatService = ref.read(chatServiceProvider);
  return await chatService.getConversations();
});

