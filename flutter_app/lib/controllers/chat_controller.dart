import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatController extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final ChatService _chatService;
  final String conversationId;

  ChatController(this._chatService, this.conversationId) : super(const AsyncValue.loading()) {
    _chatService.joinConversation(conversationId);
    loadMessages();
    _setupListeners();
  }

  void _setupListeners() {
    _chatService.onMessage((message) {
      if (message.conversationId == conversationId) {
        final currentMessages = state.value ?? [];
        state = AsyncValue.data([...currentMessages, message]);
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

  Future<void> sendMessage(String content) async {
    try {
      _chatService.sendMessage(
        conversationId: conversationId,
        content: content,
      );
    } catch (e) {
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

