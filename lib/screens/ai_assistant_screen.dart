import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../components/app_shell.dart';
import '../components/chat_bubble.dart';
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
  
  bool _isLoading = false;
  final bool _isInitializing = false; 
  
  final List<ChatMessage> _messages = [];

  // Groq Context Memory
  final List<Map<String, dynamic>> _apiHistory = [
    {
      "role": "system",
      "content": "You are Velo Co-pilot, a highly efficient, distraction-free Canvas LMS assistant.\n"
                 "CRITICAL RULES:\n"
                 "1. You DO NOT know the user's deadlines, grades, or announcements by default.\n"
                 "2. If the user asks about their coursework, YOU MUST use the provided tools to fetch the data first.\n"
                 "3. Be incredibly concise. Use bullet points and bold text for easy scanning.\n"
                 "4. When asked to plan or organize, automatically break down large assignments into logical, step-by-step daily milestones."
    }
  ];

  // Groq Tool Definitions
  final List<Map<String, dynamic>> _tools = [
    {
      "type": "function",
      "function": {
        "name": "get_pending_tasks",
        "description": "Fetches the user's pending Canvas assignments and deadlines.",
        "parameters": { "type": "object", "properties": {} }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_course_grades",
        "description": "Fetches the user's current grades for all enrolled courses.",
        "parameters": { "type": "object", "properties": {} }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_recent_announcements",
        "description": "Fetches recent announcements across all courses.",
        "parameters": { "type": "object", "properties": {} }
      }
    }
  ];

  @override
  void initState() {
    super.initState();
    _runOpeningAnimation();
  }

  void _runOpeningAnimation() async {
    // Brief pause as the screen transitions in
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessage(text: "Hello there! 👋", isUser: false));
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _messages.add(ChatMessage(
        text: "Hi! I'm Velo Co-pilot. I have securely loaded your grades, assignments, and deadlines. What do you need?",
        isUser: false,
      ));
    });
    
    _scrollToBottom();
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
    
    _apiHistory.add({"role": "user", "content": text});

    try {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception("GROQ_API_KEY missing in .env");

      bool toolCallMade = true;
      String finalResponseText = "I am having trouble processing that right now.";

      while (toolCallMade) {
        toolCallMade = false;
        http.Response? response;
        
        const int maxRetries = 3;
        for (int attempt = 0; attempt < maxRetries; attempt++) {
          response = await http.post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "model": "openai/gpt-oss-120b",
              "messages": _apiHistory,
              "tools": _tools,
              "tool_choice": "auto"
            }),
          );

          if (response.statusCode == 429 || response.statusCode >= 500) {
            if (attempt < maxRetries - 1) {
              final waitSeconds = 2 * (attempt + 1);
              debugPrint('Groq limit/server error (${response.statusCode}). Retrying in ${waitSeconds}s...');
              await Future.delayed(Duration(seconds: waitSeconds));
              continue;
            }
          }
          break;
        }

        if (response == null || response.statusCode != 200) {
          throw Exception('Groq API Error: ${response?.statusCode ?? 'Unknown'} - ${response?.body ?? ''}');
        }

        final responseData = jsonDecode(response.body);
        final responseMessage = responseData['choices'][0]['message'];
        
        Map<String, dynamic> assistantMessage = {"role": "assistant"};
        if (responseMessage['content'] != null) {
          assistantMessage["content"] = responseMessage['content'];
        }
        if (responseMessage['tool_calls'] != null) {
          assistantMessage["tool_calls"] = responseMessage['tool_calls'];
        }
        _apiHistory.add(assistantMessage);

        if (responseMessage['tool_calls'] != null) {
          toolCallMade = true;
          final toolCalls = responseMessage['tool_calls'] as List;

          for (var toolCall in toolCalls) {
            final functionName = toolCall['function']['name'];
            final toolCallId = toolCall['id'];
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Accessing Canvas: $functionName...'), 
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            String toolResult = "No data found.";
            if (functionName == 'get_pending_tasks') {
              toolResult = await _canvasService.buildTasksContext();
            } else if (functionName == 'get_course_grades') {
              toolResult = await _canvasService.buildGradesContext();
            } else if (functionName == 'get_recent_announcements') {
              toolResult = await _canvasService.buildAnnouncementsContext();
            }

            _apiHistory.add({
              "role": "tool",
              "tool_call_id": toolCallId,
              "name": functionName,
              "content": toolResult
            });
          }
        } else {
          finalResponseText = responseMessage['content'] ?? "No response.";
        }
      }

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: finalResponseText, isUser: false));
        });
      }
    } catch (e) {
      debugPrint('AI ERROR: $e'); 
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Connection error. Please try again.',
            isUser: false
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
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
      title: 'Velo Co-pilot',
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