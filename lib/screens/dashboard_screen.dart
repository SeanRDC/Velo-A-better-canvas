// Master Dashboard Screen
import 'package:flutter/material.dart';
import '../components/app_shell.dart';
import '../components/task_card.dart';
import '../models/task.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Temporary mock content before live API in later versions
  final List<Task> _mockTasks = [
    Task(
      id: '1',
      title: 'Configure OSPF Routing',
      courseName: 'Routing and Switching',
      courseCode: 'NET 201',
      dueDate: DateTime.now().subtract(const Duration(days: 1)), // Overdue
      points: 50,
      type: 'assignment',
    ),
    Task(
      id: '2',
      title: 'Midterm UI Prototype',
      courseName: 'Applications Development',
      courseCode: '6ADET',
      dueDate: DateTime.now().add(const Duration(days: 2)), // Upcoming
      points: 100,
      type: 'assignment',
    ),
    Task(
      id: '3',
      title: 'Chapter 4 Reading Quiz',
      courseName: 'Information Assurance',
      courseCode: 'SEC 305',
      dueDate: DateTime.now().add(const Duration(days: 5)),
      points: 20,
      type: 'quiz',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'My Tasks',
      activeTab: 'tasks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                _buildFilterChip('All', true, theme),
                const SizedBox(width: 8),
                _buildFilterChip('NET 201', false, theme),
                const SizedBox(width: 8),
                _buildFilterChip('6ADET', false, theme),
                const SizedBox(width: 8),
                _buildFilterChip('SEC 305', false, theme),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _mockTasks.length,
              itemBuilder: (context, index) {
                final task = _mockTasks[index];
                return TaskCard(
                  task: task,
                  onTap: () {
                    // TODO: Route to assignment details and submission overlay
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
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
    );
  }
}