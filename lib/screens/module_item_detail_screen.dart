// Module Item Detail Screen (Canvas Progression)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../components/app_shell.dart';
import '../models/course.dart';
import '../services/canvas_service.dart';
import 'course_modules_screen.dart'; // To access the ModuleItem model

class ModuleItemDetailScreen extends StatefulWidget {
  final Course course;
  final List<ModuleItem> items;
  final int initialIndex;

  const ModuleItemDetailScreen({
    super.key,
    required this.course,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<ModuleItemDetailScreen> createState() => _ModuleItemDetailScreenState();
}

class _ModuleItemDetailScreenState extends State<ModuleItemDetailScreen> {
  final CanvasService _canvasService = CanvasService();
  
  late int _currentIndex;
  String _htmlContent = '';
  bool _isLoading = true;
  
  // Submission state
  bool _submitted = false;
  bool _isUploading = false;
  String _selectedTab = 'file';
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadCurrentItem();
  }

  Future<void> _loadCurrentItem() async {
    setState(() => _isLoading = true);
    final item = widget.items[_currentIndex];
    
    final html = await _canvasService.fetchModuleItemHtml(
      widget.course.id, 
      item.kind, 
      item.pageUrl, 
      item.apiUrl,
    );

    if (mounted) {
      setState(() {
        _htmlContent = html;
        _isLoading = false;
      });
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _loadCurrentItem();
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.items.length - 1) {
      setState(() => _currentIndex++);
      _loadCurrentItem();
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openSubmitSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final canSubmit = _selectedTab == 'file' || _textController.text.trim().isNotEmpty;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24, right: 24, top: 12,
              ),
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
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _selectedTab = 'file'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 'file' ? theme.colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text('File upload', style: TextStyle(fontWeight: FontWeight.w600, color: _selectedTab == 'file' ? theme.colorScheme.onPrimary : theme.colorScheme.secondary)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _selectedTab = 'text'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 'text' ? theme.colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text('Text entry', style: TextStyle(fontWeight: FontWeight.w600, color: _selectedTab == 'text' ? theme.colorScheme.onPrimary : theme.colorScheme.secondary)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedTab == 'file')
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 32, color: theme.colorScheme.secondary),
                            const SizedBox(height: 8),
                            Text('Choose a file', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                            Text('PDF, DOCX, ZIP up to 50 MB', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    TextField(
                      controller: _textController,
                      maxLines: 5,
                      onChanged: (val) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Type your submission here...', filled: true, fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canSubmit && !_isUploading
                          ? () async {
                              setModalState(() => _isUploading = true);
                              await Future.delayed(const Duration(milliseconds: 900)); // Simulate API call
                              setState(() => _submitted = true);
                              if (context.mounted) Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isUploading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                          : Text(_submitted ? 'Submitted' : 'Submit to Canvas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentItem = widget.items[_currentIndex];
    
    final canGoBack = _currentIndex > 0;
    final canGoForward = _currentIndex < widget.items.length - 1;

    return AppShell(
      title: widget.course.courseCode,
      activeTab: 'courses',
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () => context.pop(),
      ),
      child: Column(
        children: [
          // Content Area
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentItem.kind.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentItem.label,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_htmlContent.isNotEmpty)
                      HtmlWidget(
                        _htmlContent,
                        onTapUrl: (url) async {
                          await _launchExternalUrl(url);
                          return true;
                        },
                        textStyle: TextStyle(
                          fontSize: 16.0,
                          color: theme.colorScheme.onSurface,
                          height: 1.6,
                        ),
                        customStylesBuilder: (element) {
                          if (element.localName == 'a') {
                            return {'font-weight': '600', 'text-decoration': 'underline'};
                          }
                          return null;
                        },
                      )
                    else
                      // Fallback for Files, Quizzes, or External Tools
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.launch, size: 48, color: theme.colorScheme.secondary),
                            const SizedBox(height: 16),
                            Text(
                              'This item requires Canvas',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap below to open this ${currentItem.kind} securely in your browser.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => _launchExternalUrl(currentItem.htmlUrl),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                elevation: 0,
                              ),
                              child: const Text('Open in Canvas'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
          ),
          
          // Persistent Bottom Navigation & Submission Bar
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12, 
              bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Only show the submit button if this module item is an assignment
                if (currentItem.kind.toLowerCase() == 'assignment') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openSubmitSheet(theme),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        _submitted ? 'Resubmit' : 'Submit Assignment',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: canGoBack ? _goToPrevious : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        disabledForegroundColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    TextButton(
                      onPressed: canGoForward ? _goToNext : null,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        disabledForegroundColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Next'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}