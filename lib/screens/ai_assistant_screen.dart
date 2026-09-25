// Conversational AI Interface
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../components/app_shell.dart';
import '../components/chat_bubble.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late final GenerativeModel _model;
  late final ChatSession _chat;
  
  bool _isLoading = false;
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi Sean! I'm your Canvas Co-pilot. I can check your grades, summarize announcements, or look up deadlines. What do you need?",
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
  
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    
    // DIAGNOSTIC CHECK 1: Is the key actually loading?
    if (apiKey.isEmpty) {
      debugPrint('CRITICAL DIAGNOSTIC: API Key is EMPTY. .env failed to load.');
    } else {
      debugPrint('CRITICAL DIAGNOSTIC: API Key loaded successfully. Starts with: ${apiKey.length > 4 ? apiKey.substring(0, 4) : "INVALID"}');
    }
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "You are Velo, a distraction-free Canvas LMS Co-pilot for a university student. Keep answers concise, factual, and strictly relevant to academic scheduling.",
      ),
    );
    
    _chat = _model.startChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final responseText = response.text ?? 'I am having trouble processing that right now.';
      
      setState(() {
        _messages.add(ChatMessage(text: responseText, isUser: false));
      });
    } catch (e, stackTrace) {
      // DIAGNOSTIC CHECK 2: What is the actual exception?
      debugPrint('CRITICAL DIAGNOSTIC ERROR: $e');
      debugPrint('CRITICAL DIAGNOSTIC STACKTRACE: $stackTrace');
      
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error caught: $e', // Displaying the error in the UI temporarily
          isUser: false
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final theme = Theme.of(context);

    return AppShell(
      title: 'Canvas Co-pilot',
      activeTab: 'assistant',
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatBubble(
                  text: msg.text,
                  isUser: msg.isUser,
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(
                  strokeWidth: 2, 
                  color: theme.colorScheme.primary
                )
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask your Co-pilot...',
                        hintStyle: TextStyle(color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _isLoading 
                      ? theme.colorScheme.surface 
                      : theme.colorScheme.primary,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_upward, 
                        color: _isLoading ? theme.colorScheme.secondary : theme.colorScheme.onPrimary, 
                        size: 20
                      ),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}