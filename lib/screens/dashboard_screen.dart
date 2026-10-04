// "To do" home screen: summary counts and a grouped list of upcoming Canvas tasks with course filters
// and sorting, plus a shortcut to the planner.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../components/app_shell.dart';
import '../components/task_card.dart';
import '../models/task.dart';
import '../services/canvas_refresh.dart';
import '../services/canvas_service.dart';
import '../models/course.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with CanvasRefreshMixin<DashboardScreen> {
  final CanvasService _canvasService = CanvasService();
  final ScrollController _scrollController = ScrollController();
  
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  List<String> _courseCodes = [];
  
  String _activeFilter = 'All';
  String _sortBy = 'soonest';
  
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFabVisible = true;

  final Map<String, String> _sortLabels = {
    'soonest': 'Soonest first',
    'course': 'By course',
  };

  final Map<String, String> _sortShortLabels = {
    'soonest': 'Soonest',
    'course': 'By course',
  };

  final GlobalKey _overdueKey = GlobalKey();
  final GlobalKey _todayKey = GlobalKey();
  final GlobalKey _laterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchCanvasData();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void onCanvasRefreshed() => _fetchCanvasData(silent: true);

  Future<void> _fetchCanvasData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final tasks = await _canvasService.fetchAllActiveTasks();
      
      if (!mounted) return;

      final Set<String> uniqueCodes = {};
      for (var task in tasks) {
        uniqueCodes.add(task.courseCode);
      }

      _allTasks = tasks;
      _courseCodes = uniqueCodes.toList()..sort();
      _applyFilterAndSort();
      _isLoading = false;
      if (mounted) {
        context.read<AppState>().scheduleDeadlines(_allTasks);
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilterAndSort() {
    final now = DateTime.now();
    final maxDate = now.add(const Duration(days: 14));

    List<Task> list = _allTasks.where((t) {
      if (t.isSubmitted) return false;
      if (t.dueDate.isAfter(maxDate)) return false; 
      return true;
    }).toList();

    if (_activeFilter != 'All') {
      list = list.where((t) => t.courseCode == _activeFilter).toList();
    }

    if (_sortBy == 'soonest') {
      List<Task> upcoming = [];
      List<Task> overdue = [];
      
      final today = DateTime(now.year, now.month, now.day);
      
      for (var t in list) {
        final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
        if (taskDate.isBefore(today)) {
          overdue.add(t);
        } else {
          upcoming.add(t);
        }
      }
      
      upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      overdue.sort((a, b) => a.dueDate.compareTo(b.dueDate)); 
      
      list = [...overdue, ...upcoming];
    } else {
      list.sort((a, b) => a.courseCode.compareTo(b.courseCode));
    }
    
    if (mounted) {
      setState(() {
        _filteredTasks = list;
      });
    }
  }

  void _setFilter(String filter) {
    _activeFilter = filter;
    _applyFilterAndSort();
  }

  void _setSortBy(String sortKey) {
    _sortBy = sortKey;
    _applyFilterAndSort();
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    'Sort tasks by',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ..._sortLabels.keys.map((key) {
                  final isSelected = _sortBy == key;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _setSortBy(key);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _sortLabels[key]!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToSection(List<GlobalKey> candidates) {
    void scroll() {
      for (final key in candidates) {
        final target = key.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
          return;
        }
      }
    }

    if (_sortBy != 'soonest') {
      _setSortBy('soonest');
      WidgetsBinding.instance.addPostFrameCallback((_) => scroll());
    } else {
      scroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    int overdueCount = 0;
    int todayCount = 0;
    int weekCount = 0;
    for (final task in _filteredTasks) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      if (task.dueDate.isBefore(now)) overdueCount++;
      if (taskDate == today) todayCount++;
      if (!taskDate.isBefore(today) && taskDate.isBefore(weekEnd)) weekCount++;
    }
    final hasData = !_isLoading || _allTasks.isNotEmpty;

    return AppShell(
      title: 'To do',
      activeTab: 'tasks',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            onPressed: _showSortSheet,
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurface),
            icon: const Icon(Icons.swap_vert, size: 18),
            label: Text(
              _sortShortLabels[_sortBy]!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryTile(
                            theme,
                            value: hasData ? '$overdueCount' : '–',
                            label: 'Overdue',
                            alert: overdueCount > 0,
                            onTap: () => _scrollToSection([_overdueKey, _todayKey]),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryTile(
                            theme,
                            value: hasData ? '$todayCount' : '–',
                            label: 'Due today',
                            alert: false,
                            onTap: () => _scrollToSection([_todayKey, _laterKey]),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryTile(
                            theme,
                            value: hasData ? '$weekCount' : '–',
                            label: 'This week',
                            alert: false,
                            onTap: () => _scrollToSection([_laterKey, _todayKey]),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Row(
                      children: [
                        _buildFilterChip('All', _activeFilter == 'All', theme),
                        ..._courseCodes.map((code) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: _buildFilterChip(code, _activeFilter == code, theme),
                          );
                        }),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _buildContent(theme),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 24,
            right: 24,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              offset: _isFabVisible ? Offset.zero : const Offset(0, 2.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isFabVisible ? 1.0 : 0.0,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    context.go('/planner');
                  },
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 4,
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text('Auto-Plan', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
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
              Text('Failed to sync with Canvas.', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchCanvasData,
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, elevation: 0),
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 64, width: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                child: Icon(Icons.check, size: 32, color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 16),
              Text('Nothing to do here', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('No active tasks match this filter.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    bool isOverdueDay(Task task) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return taskDate.isBefore(today);
    }

    String groupOf(Task task) {
      if (_sortBy != 'soonest') return task.courseCode;

      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      if (taskDate.isBefore(today)) return 'Overdue';
      if (taskDate == today) return 'Today';
      if (taskDate == tomorrow) return 'Tomorrow';
      return DateFormat('EEE, MMM d').format(taskDate);
    }

    final Map<String, int> groupCounts = {};
    for (final task in _filteredTasks) {
      final countKey = '${isOverdueDay(task)}:${groupOf(task)}';
      groupCounts[countKey] = (groupCounts[countKey] ?? 0) + 1;
    }

    final List<Widget> overdueWidgets = [];
    final List<Widget> upcomingWidgets = [];

    String? currentOverdueGroup;
    String? currentUpcomingGroup;
    bool laterKeyUsed = false;

    for (var task in _filteredTasks) {
      final isOverdueItem = isOverdueDay(task);
      final taskGroup = groupOf(task);
      final count = groupCounts['$isOverdueItem:$taskGroup']!;

      Widget? header;
      if (isOverdueItem) {
        if (taskGroup != currentOverdueGroup) {
          final key = currentOverdueGroup == null ? _overdueKey : null;
          header = _buildDivider(taskGroup, count, theme, isOverdue: true, key: key);
          currentOverdueGroup = taskGroup;
        }
      } else {
        if (taskGroup != currentUpcomingGroup) {
          Key? key;
          if (_sortBy == 'soonest' && taskGroup == 'Today') {
            key = _todayKey;
          } else if (!laterKeyUsed) {
            key = _laterKey;
            laterKeyUsed = true;
          }
          header = _buildDivider(taskGroup, count, theme, isOverdue: false, key: key);
          currentUpcomingGroup = taskGroup;
        }
      }

      final card = Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: TaskCard(
          task: task,
          onTap: () {

            final course = Course(
              id: task.courseId,
              name: task.courseName,
              courseCode: task.courseCode,
            );

            context.push('/task', extra: {
              'course': course,
              'assignment': task,
            });
          },
        ),
      );

      if (isOverdueItem) {
        if (header != null) overdueWidgets.add(header);
        overdueWidgets.add(card);
      } else {
        if (header != null) upcomingWidgets.add(header);
        upcomingWidgets.add(card);
      }
    }

    final Key centerKey = const ValueKey('upcoming-tasks');
    final bool useCenter = upcomingWidgets.isNotEmpty && overdueWidgets.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () {
        CanvasService.requestFresh();
        return _fetchCanvasData();
      },
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        center: useCenter ? centerKey : null,
        slivers: [
          if (overdueWidgets.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.only(left: 24, right: 24, bottom: upcomingWidgets.isEmpty ? 88 : 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: overdueWidgets,
                ),
              ),
            ),
          if (upcomingWidgets.isNotEmpty)
            SliverPadding(
              key: centerKey,
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 88),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: upcomingWidgets,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(
    ThemeData theme, {
    required String value,
    required String label,
    required bool alert,
    required VoidCallback onTap,
  }) {
    final borderColor = alert
        ? theme.colorScheme.error.withValues(alpha: 0.35)
        : theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: alert ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: alert ? theme.colorScheme.error : theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(String groupName, int count, ThemeData theme, {required bool isOverdue, Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Text(
        '${groupName.toUpperCase()} · $count',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isOverdue ? theme.colorScheme.error : theme.colorScheme.secondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () => _setFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
