import 'package:chatbot_app/models/chat_message.dart';
import 'package:flutter/material.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _errorMessage = '';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String get errorMessage => _errorMessage;

  ChatViewModel({ChatRepository? repository})
    : _repository = repository ?? ChatRepository() {
    _initializeChat();
  }

  void _initializeChat() {
    final welcomeMessage = ChatMessage(
      text: "Hello! I'm Luno. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(welcomeMessage);
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _errorMessage = '';

    // Kullanıcı mesajını ekle
    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isTyping = true;
    notifyListeners();

    try {
      // AI yanıtını al
      final aiResponse = await _repository.getAIResponse(text);

      final aiMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(aiMessage);
    } catch (error) {
      _errorMessage = error.toString();
      final errorMessage = ChatMessage(
        text: 'Sorry, There was a mistake: ${error.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _initializeChat();
  }

  void deleteMessage(String messageId) {
    _messages.removeWhere((message) => message.id == messageId);
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
