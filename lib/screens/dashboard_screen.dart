// Master Dashboard Screen
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
  bool _isLoading = true;
  String? _errorMessage;

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
      
      // Extract unique course codes for the filter chips
      final Set<String> uniqueCodes = {};
      for (var task in tasks) {
        uniqueCodes.add(task.courseCode);
      }

      setState(() {
        _allTasks = tasks;
        _filteredTasks = tasks;
        _courseCodes = uniqueCodes.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      if (filter == 'All') {
        _filteredTasks = _allTasks;
      } else {
        _filteredTasks = _allTasks.where((t) => t.courseCode == filter).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'My Tasks',
      activeTab: 'tasks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
        child: Text(
          'No active tasks found.',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return TaskCard(
          task: task,
          onTap: () {
            // TODO: Route to assignment details and submission overlay
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}