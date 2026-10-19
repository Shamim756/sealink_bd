import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/datasources/ai_service.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final _aiService = AIService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': 'আসসালামু আলাইকুম! 🐟\nআমি SeaLink BD-র AI সহকারী। মাছের ছবি পাঠান, অথবা মাছের দাম, বাজারদর, রোগ-বালাই বা কোথায় পাওয়া যায়—যেকোনো প্রশ্ন করুন।',
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text.isEmpty ? '(ছবি পাঠানো হয়েছে)' : text,
        'image': _selectedImage,
      });
      _isLoading = true;
      _textController.clear();
    });
    _scrollToBottom();

    String response;
    if (_selectedImage != null) {
      response = await _aiService.chatWithImage(
        text.isEmpty ? 'এই মাছটি কী? এর দাম, বৈশিষ্ট্য ও রোগ সম্পর্কে বিস্তারিত বলো।' : text,
        _selectedImage!,
      );
      setState(() => _selectedImage = null);
    } else {
      // প্রম্পট আরও সরল এবং নির্দেশনামুক্ত করা হয়েছে
      final prompt = '''
প্রশ্ন: $text
অনুগ্রহ করে এই প্রশ্নের সরাসরি উত্তর দাও। কোনো অতিরিক্ত ভূমিকা বা হেডিং ছাড়া শুধু মূল উত্তরটি বাংলায় লেখো।
''';
      response = await _aiService.chat(prompt);
    }

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI মাছ সহকারী'),
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_selectedImage != null) _buildImagePreview(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: const Color(0xFF0077B6).withOpacity(0.2),
              child: const Icon(Icons.smart_toy, color: Color(0xFF0077B6)),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF0077B6) : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg['image'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        msg['image'],
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (msg['image'] != null) const SizedBox(height: 8),
                  Text(
                    msg['text'],
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: isUser ? 0.2 : -0.2, end: 0);
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF0077B6).withOpacity(0.2),
            child: const Icon(Icons.smart_toy, color: Color(0xFF0077B6)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0), _dot(1), _dot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat()).fadeIn(delay: (index * 200).ms).then().fadeOut(duration: 400.ms);
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_selectedImage!, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          const Text('ছবি সংযুক্ত'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => _selectedImage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Color(0xFF0077B6)),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'মাছের নাম, দাম বা সমস্যা লিখুন...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF0077B6),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
          ),
        ],
      ),
    );
  }
}