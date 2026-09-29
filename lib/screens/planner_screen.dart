// Interactive Automated Study Planner Hub
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../components/app_shell.dart';
import '../models/task.dart';
import '../models/course.dart';
import '../services/canvas_service.dart';

class Milestone {
  final String id;
  final String title;
  final int dateOffset; // Days from today
  bool isDone;

  Milestone({
    required this.id,
    required this.title,
    required this.dateOffset,
    this.isDone = false,
  });
}

class PlannerScreen extends StatefulWidget {
  final String? initialTaskId;
  const PlannerScreen({super.key, this.initialTaskId});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final CanvasService _canvasService = CanvasService();
  String _view = 'week'; // 'week' or 'month'
  
  List<Task> _activeTasks = [];
  List<Course> _courses = [];
  Task? _selectedTask;
  List<Milestone> _milestones = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final courses = await _canvasService.fetchActiveCourses();
      final tasks = await _canvasService.fetchAllActiveTasks();
      
      if (!mounted) return;

      final pendingTasks = tasks.where((t) => !t.isSubmitted).toList();
      
      // Auto-select the requested task, or the next most urgent task
      Task? targetTask;
      if (widget.initialTaskId != null) {
        targetTask = pendingTasks.firstWhere((t) => t.id == widget.initialTaskId, orElse: () => pendingTasks.first);
      } else if (pendingTasks.isNotEmpty) {
        targetTask = pendingTasks.first;
      }

      setState(() {
        _courses = courses;
        _activeTasks = pendingTasks;
        _selectedTask = targetTask;
        if (targetTask != null) _buildMockMilestones(targetTask);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // Temporary local milestone generator until full AI generation is wired
  void _buildMockMilestones(Task task) {
    final diffDays = task.dueDate.difference(DateTime.now()).inDays.clamp(1, 14);
    _milestones = [
      Milestone(id: '${task.id}-m1', title: 'Review requirements & gather resources', dateOffset: 0),
      Milestone(id: '${task.id}-m2', title: 'Complete core work layout', dateOffset: (diffDays / 2).floor()),
      Milestone(id: '${task.id}-m3', title: 'Finalize & submit ${task.title}', dateOffset: diffDays),
    ];
  }

  void _toggleMilestone(int index) {
    setState(() {
      _milestones[index].isDone = !_milestones[index].isDone;
    });
  }

  String _formatDue(int offsetDays) {
    final d = DateTime.now().add(Duration(days: offsetDays));
    return DateFormat('E, MMM d').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'Planner',
      activeTab: 'planner',
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : Column(
              children: [
                // View Toggle
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildToggleTab('week', 'Week', theme),
                        _buildToggleTab('month', 'Month', theme),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 40),
                    children: [
                      // Area Chart
                      _buildWorkloadChart(theme),

                      // Context View
                      if (_view == 'week') _buildWeekAtAGlance(theme) else _buildMonthGrid(theme),

                      // AI Milestones (Draggable)
                      _buildAiMilestones(theme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToggleTab(String key, String label, ThemeData theme) {
    final isActive = _view == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _view = key),
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
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkloadChart(ThemeData theme) {
    // Generate next 7 days of workload points
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final List<FlSpot> spots = [];
    final List<String> dayLabels = [];

    for (int i = 0; i < 7; i++) {
      final targetDate = today.add(Duration(days: i));
      dayLabels.add(DateFormat('E').format(targetDate)[0]); // S, M, T...
      
      int dailyPoints = 0;
      for (var t in _activeTasks) {
        final tDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
        if (tDate.isAtSameMomentAs(targetDate)) {
          dailyPoints += t.points;
        }
      }
      spots.add(FlSpot(i.toDouble(), dailyPoints.toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TASK TIMELINE / PLANNED WORKLOAD',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < dayLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(dayLabels[value.toInt()], style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.secondary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary.withValues(alpha: 0.3),
                            theme.colorScheme.secondary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekAtAGlance(ThemeData theme) {
    // Calculate workload per course for the next 7 days
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 7));
    
    final Map<String, int> courseTaskCount = {};
    final Map<String, int> coursePoints = {};
    int maxPoints = 1;

    for (var t in _activeTasks) {
      if (t.dueDate.isBefore(limit)) {
        courseTaskCount[t.courseId] = (courseTaskCount[t.courseId] ?? 0) + 1;
        coursePoints[t.courseId] = (coursePoints[t.courseId] ?? 0) + t.points;
      }
    }

    final activeCourses = _courses.where((c) => (courseTaskCount[c.id] ?? 0) > 0).toList();
    activeCourses.sort((a, b) => (coursePoints[b.id] ?? 0).compareTo(coursePoints[a.id] ?? 0));
    
    for (var pts in coursePoints.values) {
      if (pts > maxPoints) maxPoints = pts;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Week at a Glance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (activeCourses.isEmpty)
            Text('No tasks due in the next 7 days.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
          ...activeCourses.map((c) {
            final count = courseTaskCount[c.id] ?? 0;
            final pts = coursePoints[c.id] ?? 0;
            final pct = pts / maxPoints;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    height: 36, width: 36,
                    decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
                    child: Icon(Icons.book, size: 16, color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(4)),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$count', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('tasks', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(ThemeData theme) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOffset = DateTime(now.year, now.month, 1).weekday % 7; // 0=Sun, 1=Mon

    final Set<int> milestoneDays = _milestones.map((m) => now.add(Duration(days: m.dateOffset)).day).toSet();
    final int? dueDay = _selectedTask?.dueDate.month == now.month ? _selectedTask!.dueDate.day : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(DateFormat('MMMM yyyy').format(now), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.0),
              itemCount: firstDayOffset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstDayOffset) return const SizedBox.shrink();
                final day = index - firstDayOffset + 1;
                
                final isToday = day == now.day;
                final isDue = day == dueDay;
                final hasMilestone = milestoneDays.contains(day);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 28, width: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDue ? theme.colorScheme.primary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isDue || isToday ? FontWeight.bold : FontWeight.normal,
                          color: isDue 
                              ? theme.colorScheme.onPrimary 
                              : isToday 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasMilestone && !isDue)
                      Container(height: 4, width: 4, decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiMilestones(ThemeData theme) {
    if (_selectedTask == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.calendar_month_outlined, size: 48, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text('No plan yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Tap Auto-Plan on any task in your Dashboard to break its deadline into daily milestones.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
              ),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      );
    }

    final doneCount = _milestones.where((m) => m.isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary Highlight Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.onPrimary.withValues(alpha: 0.9)),
                        const SizedBox(width: 6),
                        Text(
                          'AI-PLANNED SCHEDULE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedTask!.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedTask!.courseCode}   Due ${_formatDue(_selectedTask!.dueDate.difference(DateTime.now()).inDays)}   ${_milestones.length} milestones',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Daily milestones', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('$doneCount/${_milestones.length} done', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 12, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text('Hold and drag the right handle to reschedule a step', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                ],
              ),
            ],
          ),
        ),

        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24), // Fixes the offset bug
          proxyDecorator: (Widget child, int index, Animation<double> animation) {
            return Material(
              color: Colors.transparent,
              elevation: 0,
              child: child,
            );
          },
          itemCount: _milestones.length,
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _milestones.removeAt(oldIndex);
              _milestones.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final m = _milestones[index];
            
            return Padding(
              key: ValueKey(m.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _toggleMilestone(index),
                        child: Icon(
                          m.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: m.isDone ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: m.isDone ? theme.colorScheme.secondary : theme.colorScheme.onSurface,
                                decoration: m.isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Day ${index + 1}   ${_formatDue(m.dateOffset)}',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                            ),
                          ],
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(Icons.drag_indicator, color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}