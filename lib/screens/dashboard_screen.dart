import 'package:flutter/material.dart';
import '../components/app_shell.dart';
import '../components/task_card.dart';
import '../models/task.dart';
import '../services/canvas_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CanvasService _canvasService = CanvasService();
  
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  List<String> _courseCodes = [];
  
  String _activeFilter = 'All';
  String _sortBy = 'soonest';
  
  bool _isLoading = true;
  String? _errorMessage;

  final Map<String, String> _sortLabels = {
    'soonest': 'Soonest first',
    'course': 'By course',
    'points': 'By points',
  };

  @override
  void initState() {
    super.initState();
    _fetchCanvasData();
  }

  Future<void> _fetchCanvasData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
    } catch (e) {
      if (!mounted) return; 
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilterAndSort() {
    List<Task> list = _allTasks.where((t) => !t.isSubmitted).toList(); 
    if (_activeFilter != 'All') {
      list = list.where((t) => t.courseCode == _activeFilter).toList();
    }
    list.sort((a, b) {
      if (_sortBy == 'soonest') {
        return a.dueDate.compareTo(b.dueDate);
      } else if (_sortBy == 'points') {
        final double ptsA = (a.points).toDouble();
        final double ptsB = (b.points).toDouble();
        return ptsB.compareTo(ptsA); 
      } else {
        return a.courseCode.compareTo(b.courseCode);
      }
    });
    
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

  bool _isOverdue(Task task) {
    return task.dueDate.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdueCount = _filteredTasks.where(_isOverdue).length;

    return AppShell(
      title: 'My Tasks',
      activeTab: 'tasks',
      // WiFi icon action removed here
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary + sort header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_filteredTasks.length} active tasks',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      overdueCount > 0 
                          ? '$overdueCount overdue · needs attention' 
                          : "You're on track",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: overdueCount > 0 ? theme.colorScheme.error : theme.colorScheme.secondary,
                        fontWeight: overdueCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _showSortSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.swap_vert, size: 16, color: theme.colorScheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          _sortLabels[_sortBy]!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips (Scrollable left to right)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(), // Ensures smooth horizontal scrolling
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
          
          // Main Content Area
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
                'Failed to sync with Canvas.',
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
                onPressed: _fetchCanvasData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                ),
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
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(Icons.check, size: 32, color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 16),
              Text(
                'Nothing pending here',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'No active tasks match this filter.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800), // Caps width on tablets/web
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: _filteredTasks.length,
          itemBuilder: (context, index) {
            final task = _filteredTasks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TaskCard(
                task: task,
                onTap: () {
                  // TODO: Route to assignment details and submission overlay
                },
              ),
            );
          },
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