import 'package:chatbot_app/models/chat_message.dart';
import 'package:chatbot_app/viewmodels/chat_viewmodels.dart';
import 'package:chatbot_app/views/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatView extends StatefulWidget {
  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late ChatViewModel _viewModel;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    _viewModel.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LunoChat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _viewModel.isTyping ? 'typing...' : 'Online',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        actions: [
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.info_outline),
            onPressed: () => _showApiInfoDialog(),
          ),
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.clear_all),
            onPressed: () => _showClearChatDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_viewModel.errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Text(
                  _viewModel.errorMessage,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: EdgeInsets.all(16),
      itemCount: _viewModel.messages.length + (_viewModel.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Eğer typing varsa ve son item ise, typing indicator'ü göster
        if (_viewModel.isTyping && index == _viewModel.messages.length) {
          return _buildTypingIndicator();
        }

        final message = _viewModel.messages[index];

        return MessageBubble(
          message: message,
          onDelete: () => _viewModel.deleteMessage(message.id),
        );
      },
    );
  }

  void _showApiInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('API Info'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🤖 llama-3.1-8b-instant'),
              SizedBox(height: 8),
              Text(
                ApiConfig.hasKey ? '✅ API key active' : '❌ API key inactive',
                style: TextStyle(
                  color: ApiConfig.hasKey ? Colors.green : Colors.red,
                ),
              ),
              if (!ApiConfig.hasKey) ...[
                SizedBox(height: 8),
                Text(
                  'add API_KEY to .env file',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SizedBox(
              width: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [_buildDot(0), _buildDot(1), _buildDot(2)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade500,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Write your message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _handleSubmitted,
                  enabled: !_viewModel.isTyping,
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed:
                    _viewModel.isTyping
                        ? null
                        : () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clean Chat'),
          content: Text('Are you sure you want to clear the chat history?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Clear'),
              onPressed: () {
                _viewModel.clearChat();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
