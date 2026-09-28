// Conversational AI Interface
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../components/app_shell.dart';
import '../components/chat_bubble.dart';
import 'dart:math' as math;
import '../services/canvas_service.dart';

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
  final CanvasService _canvasService = CanvasService();
  
  late final GenerativeModel _model;
  late final ChatSession _chat;
  
  bool _isLoading = false;
  bool _isInitializing = true; 
  
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi! I'm your Canvas Co-pilot. I have securely loaded your grades, assignments, and deadlines. What do you need?",
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAi();
  }

  Future<void> _initAi() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    
    if (apiKey.isEmpty) {
      debugPrint('CRITICAL DIAGNOSTIC: API Key is EMPTY. .env failed to load.');
    }
    
    final tools = [
      Tool(functionDeclarations: [
        FunctionDeclaration(
          'get_pending_tasks',
          'Fetches the user\'s pending Canvas assignments and deadlines.',
          Schema(SchemaType.object, properties: {})
        ),
        FunctionDeclaration(
          'get_course_grades',
          'Fetches the user\'s current grades for all enrolled courses.',
          Schema(SchemaType.object, properties: {})
        ),
        FunctionDeclaration(
          'get_recent_announcements',
          'Fetches recent announcements across all courses.',
          Schema(SchemaType.object, properties: {})
        ),
      ])
    ];

    _model = GenerativeModel(
      model: 'gemini-3.5-flash', 
      apiKey: apiKey,
      tools: tools,
      systemInstruction: Content.system(
        '''You are Velo, a distraction-free Canvas LMS Co-pilot. 
CRITICAL RULES:
1. You DO NOT know the user's deadlines, grades, or announcements by default.
2. If the user asks about their coursework, YOU MUST use the provided tools to fetch the data first.
3. Be incredibly concise. Use bullet points and bold text for easy scanning.
4. When asked to plan or organize, break down large assignments into step-by-step daily milestones.'''
      ),
    );
    
    _chat = _model.startChat();
    
    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    
    _controller.clear();
    _scrollToBottom();

    try {
      late GenerateContentResponse response;
      const int maxRetries = 4;
      final random = math.Random();
      
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          response = await _chat.sendMessage(Content.text(text));
          
          while (response.functionCalls.isNotEmpty) {
            final call = response.functionCalls.first;
            Map<String, Object?> resultData = {};
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Accessing Canvas: ${call.name}...'), 
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            if (call.name == 'get_pending_tasks') {
              resultData = {'data': await _canvasService.buildTasksContext()};
            } else if (call.name == 'get_course_grades') {
              resultData = {'data': await _canvasService.buildGradesContext()};
            } else if (call.name == 'get_recent_announcements') {
              resultData = {'data': await _canvasService.buildAnnouncementsContext()};
            }
            
            response = await _chat.sendMessage(Content.functionResponse(call.name, resultData));
          }

          
          break;
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          final isRateLimit = errorStr.contains('429') || 
                              errorStr.contains('quota') || 
                              errorStr.contains('exhausted');
                              
          if (isRateLimit && attempt < maxRetries - 1) {
            final int baseDelay = 2000 * (1 << attempt);
            
            final int jitteredDelay = random.nextInt(baseDelay + 1);
            
            final int totalDelayMs = 1000 + jitteredDelay; 
            
            debugPrint('Rate limit hit. Retrying in ${totalDelayMs}ms (Attempt ${attempt + 1})');
            await Future.delayed(Duration(milliseconds: totalDelayMs));
            continue;
          }
          rethrow;
        }
      }

      final responseText = response.text ?? 'I am having trouble processing that right now.';
      
      setState(() {
        _messages.add(ChatMessage(text: responseText, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Connection error or rate limit exhausted. Please try again later.', 
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
      child: _isInitializing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading local course context...',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                  ),
                ],
              ),
            )
          : Column(
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