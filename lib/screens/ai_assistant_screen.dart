// AI assistant chat screen that sends the conversation to Groq and lets the model call tools
// to look up the user's live Canvas data.
import 'package:flutter/material.dart';
import 'dart:convert';
import '../components/app_shell.dart';
import '../components/chat_bubble.dart';
import '../services/canvas_service.dart';
import '../services/groq_service.dart';
import '../services/safe_launch.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  static void resetConversation() => _AiAssistantScreenState._resetConversation();

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class TypingBubble extends StatefulWidget {
  final String status;
  final IconData? icon;

  const TypingBubble({super.key, this.status = 'Thinking', this.icon});
  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 16),
          Container(
            margin: const EdgeInsets.only(top: 2),
            height: 28, width: 28,
            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
            child: Icon(Icons.smart_toy_outlined, size: 16, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final offset = math.sin((_controller.value * 2 * math.pi) - (index * 1.5)) * 3;
                          return Transform.translate(
                            offset: Offset(0, offset),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 6, width: 6,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    const SizedBox(width: 10),
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, ?current],
                        ),
                        child: Row(
                          key: ValueKey(widget.status),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, size: 14, color: theme.colorScheme.secondary),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                widget.status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CanvasService _canvasService = CanvasService();
  final GroqService _groqService = GroqService();
  bool _isLoading = false;
  bool _isCooldown = false;
  bool _isTyping = false;

  static const String _goOnlineLink = 'velo://go-online';
  static const String _offlineReply =
      "**You're in offline mode.** I can't answer questions or look up your tasks, grades, announcements or messages right now, because that needs a connection to the AI service and Canvas.\n\n"
      "You can still browse what's saved on this device: your To do list, Courses, Planner and Inbox.\n\n"
      "[Switch to online mode]($_goOnlineLink) to chat with me.";

  String _status = 'Thinking';
  IconData? _statusIcon;

  static (String, IconData) _toolStatus(String functionName, Map<String, dynamic> args) {
    switch (functionName) {
      case 'get_pending_tasks':
        return ('Checking your tasks', Icons.checklist_outlined);
      case 'get_course_grades':
        return ('Looking up your grades', Icons.school_outlined);
      case 'get_recent_announcements':
        return ('Reading announcements', Icons.campaign_outlined);
      case 'get_messages':
        final folder = args['folder'];
        final label = folder == 'sent'
            ? 'Checking sent messages'
            : folder == 'archived'
                ? 'Checking archived messages'
                : 'Checking your inbox';
        return (label, Icons.mail_outline);
      case 'get_thread_details':
        return ('Reading the conversation', Icons.forum_outlined);
      case 'get_assignment_details':
        return ('Reading the assignment details', Icons.description_outlined);
      default:
        return ('Checking Canvas', Icons.cloud_outlined);
    }
  }
  final bool _isInitializing = false; 


  static bool _hasWelcomed = false;
  static final List<ChatMessage> _messages = [];
  static final List<Map<String, dynamic>> _apiHistory = [
    {
      "role": "system",
      "content": "You are Velo Co-pilot, a highly efficient, distraction-free Canvas LMS assistant.\n"
                 "CRITICAL RULES:\n"
                 "1. You DO NOT know the user's deadlines or grades by default. Use tools to fetch data first.\n"
                 "2. Be incredibly concise. Use bullet points and bold text for easy scanning.\n"
                 "3. When asked to plan or organize, automatically break down large assignments into logical daily milestones.\n"
                 "4. If the user asks for instructions on an assignment, use the get_assignment_details tool.\n"
                 "5. If the user asks about messages, use get_messages. To read a specific message, use get_thread_details.\n"
                 "6. NEVER show raw message IDs, thread IDs, or internal database identifiers to the user in plain text.\n"
                 "7. CRITICAL: When listing tasks, announcements, or messages, ALWAYS embed a markdown link using the EXACT `velo://` URL provided in the tool data. Format it like this: `[Item Name](velo://...)`.\n"
                 "8. FORMATTING: Replies are usually read on a phone. Use a table only for compact data with at most 3 short columns (for example Course | Grade), keep every cell brief, and never put links or long names in a table. For anything longer, use a bulleted list with one item per line."
    }
  ];

  static void _resetConversation() {
    _hasWelcomed = false;
    _messages.clear();
    _apiHistory.removeRange(1, _apiHistory.length);
  }

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
    },
    {
      "type": "function",
      "function": {
        "name": "get_messages",
        "description": "Fetches a list of recent messages from the user's Canvas inbox, sent, or archived folders.",
        "parameters": {
          "type": "object",
          "properties": {
            "folder": {
              "type": "string",
              "description": "The folder to look in. Can be 'inbox', 'sent', or 'archived'."
            }
          }
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_thread_details",
        "description": "Fetches the full back-and-forth conversation history of a specific message thread.",
        "parameters": {
          "type": "object",
          "properties": {
            "thread_id": {
              "type": "string",
              "description": "The ID of the message thread to read."
            }
          },
          "required": ["thread_id"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_assignment_details",
        "description": "Fetches the full description and instructions for a specific assignment.",
        "parameters": {
          "type": "object",
          "properties": {
            "assignment_name": {
              "type": "string",
              "description": "The exact name of the assignment to look up."
            }
          },
          "required": ["assignment_name"]
        }
      }
    }
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTypingChange);
    if (!_hasWelcomed) {
      _runOpeningAnimation();
      _hasWelcomed = true;
    } else {
      _scrollToBottom();
    }
  }

  void _handleTypingChange() {
    final isTypingNow = _controller.text.isNotEmpty;
    if (_isTyping != isTypingNow && mounted) {
      setState(() => _isTyping = isTypingNow);
    }
  }

  void _runOpeningAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessage(
        text: "Hello, I'm Velo Co-pilot. I have securely loaded your grades, assignments, and deadlines. What do you need?",
        isUser: false,
      ));
    });
    
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTypingChange);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || _isCooldown) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _status = 'Thinking';
      _statusIcon = null;
    });

    _controller.clear();
    _scrollToBottom();

    if (context.read<AppState>().isOffline) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: _offlineReply, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    _apiHistory.add({"role": "user", "content": text});

    try {
      bool toolCallMade = true;
      String finalResponseText = "I am having trouble processing that right now.";

      const int maxToolRounds = 6;
      for (int round = 0; toolCallMade && round < maxToolRounds; round++) {
        toolCallMade = false;

        final responseMessage = await _groqService.chat(messages: _apiHistory, tools: _tools);

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
              Map<String, dynamic> statusArgs = {};
              try {
                final raw = toolCall['function']['arguments']?.toString() ?? '';
                if (raw.isNotEmpty) statusArgs = Map<String, dynamic>.from(jsonDecode(raw) as Map);
              } catch (_) {}
              final (label, icon) = _toolStatus(functionName, statusArgs);
              setState(() {
                _status = label;
                _statusIcon = icon;
              });
            }

            String toolResult = "No data found.";
            if (functionName == 'get_pending_tasks') {
              toolResult = await _canvasService.buildTasksContext();
            } else if (functionName == 'get_course_grades') {
              toolResult = await _canvasService.buildGradesContext();
            } else if (functionName == 'get_recent_announcements') {
              toolResult = await _canvasService.buildAnnouncementsContext();
            } else if (functionName == 'get_messages') {
              final String argsStr = toolCall['function']['arguments']?.toString() ?? '{}';
              final args = argsStr.isEmpty ? {} : jsonDecode(argsStr);
              final folder = args['folder'] ?? 'inbox';
              toolResult = await _canvasService.buildInboxContext(folder: folder);
            } else if (functionName == 'get_thread_details') {
              final String argsStr = toolCall['function']['arguments']?.toString() ?? '{}';
              final args = argsStr.isEmpty ? {} : jsonDecode(argsStr);
              final threadId = args['thread_id']?.toString() ?? '';
              toolResult = await _canvasService.buildThreadContext(threadId);
            } else if (functionName == 'get_assignment_details') {
              final args = jsonDecode(toolCall['function']['arguments'] as String);
              final assignmentName = args['assignment_name'] ?? '';
              toolResult = await _canvasService.buildAssignmentDetailsContext(assignmentName);
            }

            _apiHistory.add({
              "role": "tool",
              "tool_call_id": toolCallId,
              "name": functionName,
              "content": toolResult
            });
          }

          if (mounted) {
            setState(() {
              _status = 'Putting it together';
              _statusIcon = null;
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
          _isCooldown = true;
        });
        _scrollToBottom();
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isCooldown = false);
        });
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

  void _handleDeepLink(String url) async {
    if (url == _goOnlineLink) {
      final appState = context.read<AppState>();
      final wasOffline = appState.isOffline;
      appState.goOnline();
      setState(() {
        _messages.add(ChatMessage(
          text: wasOffline ? "You're back online. What do you need?" : "You're already online. What do you need?",
          isUser: false,
        ));
      });
      _scrollToBottom();
      return;
    }

    if (!url.startsWith('velo://')) {
      await launchSafeUrl(url);
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (url.startsWith('velo://task')) {
        final courseId = uri.queryParameters['courseId'];
        final taskId = uri.queryParameters['taskId'];
        final courses = await _canvasService.fetchActiveCourses();
        final course = courses.firstWhere((c) => c.id == courseId);
        final tasks = await _canvasService.fetchAssignmentsForCourse(course);
        final task = tasks.firstWhere((t) => t.id == taskId);
        
        if (mounted) context.push('/task', extra: {'course': course, 'assignment': task});
      
      } else if (url.startsWith('velo://announcements')) {
        final courseId = uri.queryParameters['courseId'];
        final courses = await _canvasService.fetchActiveCourses();
        final course = courses.firstWhere((c) => c.id == courseId);
        
        if (mounted) context.push('/course-announcements', extra: course);
      
      } else if (url.startsWith('velo://conversation')) {
        final threadId = uri.queryParameters['threadId'];
        if (mounted) context.push('/conversation', extra: {'id': threadId});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load the requested item.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'Velo Co-pilot',
      activeTab: 'assistant',
      actions: [
        IconButton(
          icon: const Icon(Icons.cleaning_services_outlined),
          tooltip: 'Clear Chat',
          onPressed: () {
            setState(() {
              if (_messages.length > 1) _messages.removeRange(1, _messages.length);
              _apiHistory.removeRange(1, _apiHistory.length);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('AI memory cleared.'), duration: Duration(seconds: 2)),
            );
          },
        ),
      ],
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
                        onLinkTap: _handleDeepLink,
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  TypingBubble(status: _status, icon: _statusIcon),

                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        if (!_isTyping && _messages.length <= 3 && !_isLoading)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  "What are my pending tasks?",
                                  "Show my current grades",
                                  "Any new announcements?",
                                  "Check my inbox",
                                ].map((suggestion) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: InkWell(
                                      onTap: () {
                                        _controller.text = suggestion;
                                        _sendMessage();
                                      },
                                      borderRadius: BorderRadius.circular(24),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.scaffoldBackgroundColor,
                                          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Text(
                                          suggestion,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  onSubmitted: (_) => _sendMessage(),
                                  readOnly: _isCooldown,
                                  style: theme.textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: _isCooldown
                                        ? 'Cooling down...'
                                        : context.watch<AppState>().isOffline
                                            ? 'Offline mode: assistant unavailable'
                                            : 'Ask about your courses...',
                                    hintStyle: TextStyle(color: theme.colorScheme.secondary, fontSize: 14),
                                    filled: true,
                                    fillColor: theme.scaffoldBackgroundColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(color: theme.colorScheme.primary),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: (_isLoading || _isCooldown) ? null : _sendMessage,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  height: 40, width: 40,
                                  decoration: BoxDecoration(
                                    color: (_isLoading || _isCooldown)
                                        ? theme.colorScheme.secondary.withValues(alpha: 0.2)
                                        : theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isCooldown ? Icons.hourglass_bottom : Icons.arrow_upward,
                                    color: (_isLoading || _isCooldown) ? theme.colorScheme.secondary : theme.colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
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