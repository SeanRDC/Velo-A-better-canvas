// Compose New Message Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/app_shell.dart';
import '../models/course.dart';
import '../services/canvas_service.dart';

class ComposeMessageScreen extends StatefulWidget {
  const ComposeMessageScreen({super.key});

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final CanvasService _canvasService = CanvasService();
  
  List<Course> _courses = [];
  List<Map<String, dynamic>> _users = [];
  
  Course? _selectedCourse;
  String? _selectedUserId;
  
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  
  bool _isLoadingCourses = true;
  bool _isLoadingUsers = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await _canvasService.fetchActiveCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCourses = false);
      }
    }
  }

  Future<void> _fetchUsers(Course course) async {
    setState(() {
      _isLoadingUsers = true;
      _selectedUserId = null;
      _users = [];
    });
    try {
      final users = await _canvasService.fetchUsersForCourse(course.id);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedCourse == null || _selectedUserId == null || _bodyController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _canvasService.createConversation(
        _selectedCourse!.id, 
        _selectedUserId!, 
        _subjectController.text.trim().isNotEmpty ? _subjectController.text.trim() : 'No Subject', 
        _bodyController.text.trim()
      );
      if (mounted) {
        context.pop(true); // Return true to trigger inbox refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canSend = _selectedCourse != null && _selectedUserId != null && _bodyController.text.trim().isNotEmpty;

    return AppShell(
      title: 'New Message',
      activeTab: 'inbox',
      leading: IconButton(
        icon: const Icon(Icons.close, size: 28),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (_isSending)
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          TextButton(
            onPressed: canSend ? _sendMessage : null,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              disabledForegroundColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
            ),
            child: const Text('Send', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
      ],
      child: _isLoadingCourses 
        ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Course Selector
              DropdownButtonFormField<Course>(
                decoration: _inputDeco(theme, 'Select Course'),
                items: _courses.map((c) => DropdownMenuItem(value: c, child: Text(c.courseCode))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCourse = val);
                    _fetchUsers(val);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Recipient Selector
              if (_isLoadingUsers)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_selectedCourse != null)
                DropdownButtonFormField<String>(
                  decoration: _inputDeco(theme, 'To'),
                  initialValue: _selectedUserId,
                  items: _users.map((u) => DropdownMenuItem(value: u['id'].toString(), child: Text(u['name'] ?? 'Unknown'))).toList(),
                  onChanged: (val) => setState(() => _selectedUserId = val),
                ),
              const SizedBox(height: 16),
              
              // Subject
              TextField(
                controller: _subjectController,
                decoration: _inputDeco(theme, 'Subject'),
              ),
              const SizedBox(height: 16),
              
              // Body
              TextField(
                controller: _bodyController,
                maxLines: 12,
                minLines: 8,
                onChanged: (_) => setState((){}), // Trigger UI update for Send button validation
                decoration: _inputDeco(theme, 'Compose message...').copyWith(alignLabelWithHint: true),
              ),
            ],
          ),
    );
  }

  InputDecoration _inputDeco(ThemeData theme, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.colorScheme.secondary),
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}