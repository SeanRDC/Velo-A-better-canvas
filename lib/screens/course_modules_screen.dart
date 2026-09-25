// Course Modules Timeline Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/app_shell.dart';
import '../models/course.dart';

// Temporary models until we wire up the Canvas modules endpoint
class ModuleItem {
  final String label;
  final String kind; // 'reading', 'lab', 'quiz', 'lecture'
  ModuleItem(this.label, this.kind);
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
  // Hardcoded for UI layout testing
  final List<Module> _modules = [
    Module('Week 7', 'Dynamic Routing Protocols', [
      ModuleItem('Lecture: OSPF Areas & LSAs', 'lecture'),
      ModuleItem('Lab: Multi-Area OSPF Setup', 'lab'),
      ModuleItem('Quiz 4 Link-State Routing', 'quiz'),
    ]),
    Module('Week 6', 'IP Addressing & Subnetting', [
      ModuleItem('Reading: VLSM & CIDR', 'reading'),
      ModuleItem('Lab: Subnetting Practice', 'lab'),
    ]),
  ];

  IconData _getIconForKind(String kind) {
    switch (kind) {
      case 'reading': return Icons.menu_book_outlined;
      case 'lab': return Icons.science_outlined;
      case 'quiz': return Icons.help_outline;
      case 'lecture': return Icons.co_present_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
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
                Text(
                  '${_modules.length} sequential modules',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          // Timeline List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: List.generate(_modules.length, (index) {
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
                                        // Route to Task Detail
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
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              }),
            ),
          ),
        ],
      ),
    );
  }
}