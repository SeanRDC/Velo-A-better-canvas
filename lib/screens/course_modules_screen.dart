// Course Modules Timeline Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/app_shell.dart';
import '../models/course.dart';
import '../services/canvas_service.dart';

class ModuleItem {
  final String label;
  final String kind;
  final String htmlUrl;
  final String? apiUrl;
  final String? pageUrl;
  final int indent;

  ModuleItem(this.label, this.kind, this.htmlUrl, this.apiUrl, this.pageUrl, this.indent);
}

class Module {
  final String week;
  final String title;
  final List<ModuleItem> items;
  Module(this.week, this.title, this.items);
}

class CourseModulesScreen extends StatefulWidget {
  final Course course;

  const CourseModulesScreen({super.key, required this.course});

  @override
  State<CourseModulesScreen> createState() => _CourseModulesScreenState();
}

class _CourseModulesScreenState extends State<CourseModulesScreen> {
  final CanvasService _canvasService = CanvasService();
  
  List<Module> _modules = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  // We store a flattened list of items to power the Next/Previous buttons
  List<ModuleItem> _allNavigableItems = [];

  Future<void> _fetchModules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _canvasService.fetchModulesForCourse(widget.course.id);
      
      final List<Module> parsedModules = [];
      final List<ModuleItem> flatList = [];

      for (int i = 0; i < data.length; i++) {
        final modJson = data[i];
        final List<dynamic>? itemsJson = modJson['items'];
        
        final List<ModuleItem> items = [];
        if (itemsJson != null) {
          for (var item in itemsJson) {
            final type = item['type'] ?? 'Unknown';
            final modItem = ModuleItem(
              item['title'] ?? 'Untitled',
              type,
              item['html_url'] ?? '',
              item['url'],
              item['page_url'],
              item['indent'] ?? 0,
            );
            items.add(modItem);
            
            // SubHeaders are just labels; they aren't clickable pages
            if (type.toLowerCase() != 'subheader') {
              flatList.add(modItem);
            }
          }
        }

        parsedModules.add(Module(
          'Module ${i + 1}',
          modJson['name'] ?? 'Unnamed Module',
          items,
        ));
      }

      setState(() {
        _modules = parsedModules;
        _allNavigableItems = flatList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getIconForKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'page': return Icons.menu_book_outlined;
      case 'file': return Icons.insert_drive_file_outlined;
      case 'quiz': return Icons.help_outline;
      case 'assignment': return Icons.assignment_outlined;
      case 'discussion': return Icons.forum_outlined;
      case 'externalurl': return Icons.link;
      case 'externaltool': return Icons.build_circle_outlined;
      case 'subheader': return Icons.label_outline;
      default: return Icons.article_outlined;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'Modules',
      activeTab: 'courses',
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () => context.pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.courseCode,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                if (!_isLoading && _errorMessage == null)
                  Text(
                    '${_modules.length} sequential modules',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _buildContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load modules.',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchModules,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_modules.isEmpty) {
      return Center(
        child: Text(
          'No modules found.',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 32),
      itemCount: _modules.length,
      itemBuilder: (context, index) {
        final mod = _modules[index];
        final isLast = index == _modules.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sequential Rail
              Column(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Module Block
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mod.week,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mod.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (mod.items.isEmpty)
                        Text(
                          'No items in this module.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: List.generate(mod.items.length, (itemIndex) {
                              final item = mod.items[itemIndex];
                              final isFirstItem = itemIndex == 0;

                              return InkWell(
                                onTap: () {
                                  if (item.kind.toLowerCase() == 'subheader') return;
                                  
                                  final initialIndex = _allNavigableItems.indexOf(item);
                                  if (initialIndex != -1) {
                                    context.push('/module-item', extra: {
                                      'course': widget.course,
                                      'items': _allNavigableItems,
                                      'index': initialIndex,
                                    });
                                  }
                                },
                                borderRadius: isFirstItem 
                                    ? const BorderRadius.vertical(top: Radius.circular(16))
                                    : (itemIndex == mod.items.length - 1 
                                        ? const BorderRadius.vertical(bottom: Radius.circular(16)) 
                                        : BorderRadius.zero),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: isFirstItem 
                                        ? null 
                                        : Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
                                  ),
                                  padding: EdgeInsets.only(
                                    left: 16.0 + (item.indent * 16.0), 
                                    right: 16.0, 
                                    top: 14.0, 
                                    bottom: 14.0
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIconForKind(item.kind),
                                        size: 18,
                                        color: theme.colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.label,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _capitalize(item.kind),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}