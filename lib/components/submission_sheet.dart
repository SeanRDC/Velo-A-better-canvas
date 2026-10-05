// Bottom sheet that submits an assignment to Canvas as a file upload, text entry or website URL.
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/canvas_service.dart';
import '../services/safe_launch.dart';

const List<dynamic> inAppSubmissionTypes = ['online_upload', 'online_text_entry', 'online_url'];

String assignmentCanvasUrl(String courseId, Map<String, dynamic> assignment) {
  final htmlUrl = assignment['html_url'];
  if (htmlUrl is String && htmlUrl.isNotEmpty) return htmlUrl;
  return '/courses/$courseId/assignments/${assignment['id']}';
}

// Resolves to true once Canvas has accepted the submission.
Future<bool> showSubmissionSheet(
  BuildContext context, {
  required String courseId,
  required Map<String, dynamic> assignment,
  required bool resubmitting,
}) async {
  final theme = Theme.of(context);
  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _SubmissionSheet(courseId: courseId, assignment: assignment, resubmitting: resubmitting),
  );
  return submitted ?? false;
}

class _SubmissionSheet extends StatefulWidget {
  final String courseId;
  final Map<String, dynamic> assignment;
  final bool resubmitting;

  const _SubmissionSheet({required this.courseId, required this.assignment, required this.resubmitting});

  @override
  State<_SubmissionSheet> createState() => _SubmissionSheetState();
}

class _SubmissionSheetState extends State<_SubmissionSheet> {
  final CanvasService _canvasService = CanvasService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  late final bool _allowsFile;
  late final bool _allowsText;
  late final bool _allowsUrl;
  late final bool _allowsMedia;
  late final List<String> _allowedExtensions;

  String _selectedTab = 'file';
  PlatformFile? _file;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final List<dynamic> types = widget.assignment['submission_types'] ?? [];
    _allowsFile = types.contains('online_upload');
    _allowsText = types.contains('online_text_entry');
    _allowsUrl = types.contains('online_url');
    _allowsMedia = types.contains('media_recording');
    _allowedExtensions = ((widget.assignment['allowed_extensions'] as List<dynamic>?) ?? [])
        .map((e) => e.toString().replaceFirst('.', '').toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_allowsFile) {
      _selectedTab = 'file';
    } else if (_allowsText) {
      _selectedTab = 'text';
    } else if (_allowsUrl) {
      _selectedTab = 'url';
    } else if (_allowsMedia) {
      _selectedTab = 'media';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      (_selectedTab == 'file' && _file != null) ||
      (_selectedTab == 'text' && _textController.text.trim().isNotEmpty) ||
      (_selectedTab == 'url' && _urlController.text.trim().isNotEmpty);

  // Canvas stores text entries as HTML, so the typed text is escaped and its line breaks kept.
  String _textAsHtml(String text) {
    const escape = HtmlEscape();
    return text
        .trim()
        .split(RegExp(r'\n{2,}'))
        .map((paragraph) => '<p>${escape.convert(paragraph).replaceAll('\n', '<br>')}</p>')
        .join();
  }

  String? _normalizedUrl(String raw) {
    final trimmed = raw.trim();
    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) return null;
    return uri.toString();
  }

  Future<void> _pickFile() async {
    final picked = await FilePicker.pickFiles(
      type: _allowedExtensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: _allowedExtensions.isEmpty ? null : _allowedExtensions,
    );
    if (picked.isNotEmpty && mounted) {
      setState(() {
        _file = picked.first;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    final assignmentId = widget.assignment['id'].toString();
    final comment = _commentController.text;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (_selectedTab == 'file') {
        final file = _file!;
        final bytes = await file.readAsBytes();
        final fileId = await _canvasService.uploadSubmissionFile(widget.courseId, assignmentId, file.name, bytes);
        await _canvasService.submitAssignment(
          widget.courseId,
          assignmentId,
          type: 'online_upload',
          fileId: fileId,
          comment: comment,
        );
      } else if (_selectedTab == 'text') {
        await _canvasService.submitAssignment(
          widget.courseId,
          assignmentId,
          type: 'online_text_entry',
          body: _textAsHtml(_textController.text),
          comment: comment,
        );
      } else {
        final url = _normalizedUrl(_urlController.text);
        if (url == null) throw Exception('Enter a valid website URL.');
        await _canvasService.submitAssignment(
          widget.courseId,
          assignmentId,
          type: 'online_url',
          url: url,
          comment: comment,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = readableError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int availableTabs = [_allowsFile, _allowsText, _allowsUrl, _allowsMedia].where((e) => e).length;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4, width: 40,
                decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Submit work', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (availableTabs > 1)
              Container(
                padding: const EdgeInsets.all(4),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    if (_allowsFile) _buildTab('file', 'File', theme),
                    if (_allowsText) _buildTab('text', 'Text', theme),
                    if (_allowsUrl) _buildTab('url', 'URL', theme),
                    if (_allowsMedia) _buildTab('media', 'Media', theme),
                  ],
                ),
              ),

            if (_selectedTab == 'file') _buildFilePicker(theme),

            if (_selectedTab == 'text')
              TextField(
                controller: _textController,
                maxLines: 6,
                enabled: !_isSubmitting,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Type your submission here...', filled: true, fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

            if (_selectedTab == 'url')
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                enabled: !_isSubmitting,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'https://...', filled: true, fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

            if (_selectedTab == 'media') _buildMediaNotice(theme),

            if (_selectedTab != 'media') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 2,
                minLines: 1,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)', filled: true, fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit && !_isSubmitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                      : Text(widget.resubmitting ? 'Resubmit to Canvas' : 'Submit to Canvas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker(ThemeData theme) {
    final file = _file;
    if (file != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.attach_file, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file.name,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: _isSubmitting ? null : () => setState(() => _file = null),
              child: Text('Remove', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 32, color: theme.colorScheme.secondary),
            const SizedBox(height: 8),
            Text('Choose a file', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            if (_allowedExtensions.isNotEmpty)
              Text(
                'Allowed: ${_allowedExtensions.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaNotice(ThemeData theme) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(Icons.mic_none, size: 32, color: theme.colorScheme.secondary),
          const SizedBox(height: 8),
          Text(
            'Media recordings are submitted in Canvas',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => launchSafeUrl(assignmentCanvasUrl(widget.courseId, widget.assignment)),
            icon: const Icon(Icons.launch, size: 18),
            label: const Text('Open in Canvas'),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String tabKey, String label, ThemeData theme) {
    final isActive = _selectedTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: _isSubmitting ? null : () => setState(() => _selectedTab = tabKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
