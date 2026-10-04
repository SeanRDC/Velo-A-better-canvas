// Interactive Automated Study Planner Hub
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

import '../components/app_shell.dart';
import '../components/planner/day_sheet.dart';
import '../components/planner/milestone_editor_sheet.dart';
import '../components/planner/todays_focus_card.dart';
import '../models/task.dart';
import '../models/course.dart';
import '../models/milestone.dart';
import '../services/canvas_refresh.dart';
import '../services/canvas_service.dart';
import '../services/groq_service.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';
import '../services/planner_store.dart';

class PlannerScreen extends StatefulWidget {
  final String? initialTaskId;
  const PlannerScreen({super.key, this.initialTaskId});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with CanvasRefreshMixin<PlannerScreen> {
  final CanvasService _canvasService = CanvasService();
  final PlannerStore _store = PlannerStore();
  final GroqService _groqService = GroqService();
  String _view = 'week'; // 'week' or 'month'

  List<Task> _activeTasks = [];
  List<Course> _courses = [];
  Task? _selectedTask;
  Map<String, StudyPlan> _plans = {}; // Saved plans keyed by task id

  bool _isLoading = true;
  String? _generatingTaskId; // Task the AI is currently planning

  StudyPlan? get _plan => _selectedTask == null ? null : _plans[_selectedTask!.id];
  List<Milestone> get _milestones => _plan?.milestones ?? [];
  bool get _isGeneratingPlan => _selectedTask != null && _generatingTaskId == _selectedTask!.id;

  DateTime get _today => dateOnly(DateTime.now());

  // Whole calendar days from today, rounded so a DST shift can't drop a day
  int _daysUntil(DateTime date) => (dateOnly(date).difference(_today).inHours / 24).round();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // A background refresh brought new data: reload, keeping the selected task
  @override
  void onCanvasRefreshed() => _fetchData();

  Future<void> _fetchData() async {
    try {
      final courses = await _canvasService.fetchActiveCourses();
      final tasks = await _canvasService.fetchAllActiveTasks();

      final today = _today;

      final pendingTasks = tasks.where((t) {
        if (t.isSubmitted) return false;
        if (dateOnly(t.dueDate).isBefore(today)) return false;
        return true;
      }).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

      // An empty fetch (e.g. offline with no cache) must not wipe saved plans
      final activeIds = pendingTasks.map((t) => t.id).toSet();
      final Map<String, StudyPlan> plans;
      if (!_isLoading) {
        // Reloading after a background refresh: the plans in memory are the
        // latest (a save may still be in flight), so keep them
        plans = Map.of(_plans);
        if (tasks.isNotEmpty) plans.removeWhere((id, _) => !activeIds.contains(id));
      } else {
        plans = tasks.isEmpty ? await _store.loadAll() : await _store.prune(activeIds);
      }

      if (!mounted) return;

      // Keep the current selection on a reload; otherwise auto-select the
      // requested task, or the next most urgent task
      final wantedId = _selectedTask?.id ?? widget.initialTaskId;
      Task? targetTask;
      if (pendingTasks.isNotEmpty) {
        targetTask = pendingTasks.firstWhere((t) => t.id == wantedId, orElse: () => pendingTasks.first);
      }

      setState(() {
        _courses = courses;
        _activeTasks = pendingTasks;
        _plans = plans;
        _selectedTask = targetTask;
        _isLoading = false;
      });

      // Only fire off the AI generator when this task has no saved plan yet
      if (targetTask != null && !plans.containsKey(targetTask.id) && _generatingTaskId != targetTask.id) {
        _generatePlan(targetTask);
      }

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _selectTask(Task task) {
    setState(() => _selectedTask = task);
    if (!_plans.containsKey(task.id) && _generatingTaskId != task.id) {
      _generatePlan(task);
    }
  }

  Future<void> _generatePlan(Task task) async {
    setState(() => _generatingTaskId = task.id);

    final today = _today;
    // Calculate days remaining so the AI knows its boundary
    final diffDays = _daysUntil(task.dueDate).clamp(0, 365);
    List<Milestone> milestones;
    final isOffline = context.read<AppState>().isOffline;

    try {
      // Offline mode skips the AI and uses the generic steps below
      if (isOffline) throw Exception('Offline mode');

      String details = task.description
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (details.length > 1500) details = details.substring(0, 1500);

      final message = await _groqService.chat(
        temperature: 0.2, // Low temperature ensures consistent JSON formatting
        messages: [
            {
              "role": "system",
              "content": "You are a highly efficient study planner. Break the user's assignment down into 3 to 5 logical daily milestones that are specific to what the assignment actually asks for. Return ONLY a valid JSON array of objects. Each object must have 'title' (string), 'dateOffset' (integer, the number of days from today to do this step, must be between 0 and $diffDays) and 'minutes' (integer, a realistic estimate of the focused work time for this step). Do not include markdown formatting, code block ticks, or any extra text outside the JSON."
            },
            {
              "role": "user",
              "content": "Task: ${task.title}. Course: ${task.courseCode}. Worth ${task.points} points. Total time until due: $diffDays days. Instructions: $details"
            }
        ],
      );

      String content = message['content'] ?? '[]';

      // Failsafe: Strip markdown ticks just in case the AI includes them anyway
      content = content.replaceAll(RegExp(r'```(?:json)?\s*'), '').replaceAll(RegExp(r'```\s*'), '').trim();

      final List<dynamic> parsed = jsonDecode(content);
      if (parsed.isEmpty) throw Exception('Empty plan');

      milestones = [];
      for (int i = 0; i < parsed.length; i++) {
        final offset = ((parsed[i]['dateOffset'] as num?)?.toInt() ?? 0).clamp(0, diffDays);
        final minutes = (parsed[i]['minutes'] as num?)?.toInt();
        milestones.add(Milestone(
          id: '${task.id}-m$i',
          title: parsed[i]['title'] ?? 'Milestone ${i + 1}',
          date: DateTime(today.year, today.month, today.day + offset),
          minutes: (minutes != null && minutes > 0) ? minutes : null,
        ));
      }
    } catch (e) {
      debugPrint('Planner AI Error: $e');
      // Fallback to generic local milestones if the API fails or rate-limits
      milestones = _buildFallbackMilestones(task, diffDays);
    }

    final plan = StudyPlan(
      taskId: task.id,
      taskTitle: task.title,
      courseCode: task.courseCode,
      dueDate: task.dueDate,
      milestones: milestones,
    )..sortByDate();

    await _store.save(plan);
    if (!mounted) return;

    setState(() {
      _plans[task.id] = plan;
      if (_generatingTaskId == task.id) _generatingTaskId = null;
    });
  }

  List<Milestone> _buildFallbackMilestones(Task task, int diffDays) {
    final today = _today;
    DateTime at(int offset) => DateTime(today.year, today.month, today.day + offset);
    return [
      Milestone(id: '${task.id}-m1', title: 'Review requirements & gather resources', date: at(0)),
      Milestone(id: '${task.id}-m2', title: 'Complete core work layout', date: at((diffDays / 2).floor())),
      Milestone(id: '${task.id}-m3', title: 'Finalize & submit ${task.title}', date: at(diffDays)),
    ];
  }

  void _toggleMilestone(StudyPlan plan, Milestone milestone) {
    setState(() => milestone.isDone = !milestone.isDone);
    _store.save(plan);
  }

  // Pass null to add a new step to the selected plan
  Future<void> _editMilestone(Milestone? milestone) async {
    final plan = _plan;
    final task = _selectedTask;
    if (plan == null || task == null) return;

    final result = await showMilestoneEditor(
      context,
      milestone: milestone,
      firstDate: _today,
      lastDate: dateOnly(task.dueDate),
    );
    if (result == null || !mounted) return;

    setState(() {
      if (milestone == null) {
        plan.milestones.add(Milestone(
          id: '${task.id}-m${DateTime.now().microsecondsSinceEpoch}',
          title: result.title,
          date: result.date,
          minutes: result.minutes,
        ));
      } else if (result.delete) {
        plan.milestones.remove(milestone);
      } else {
        milestone.title = result.title;
        milestone.date = dateOnly(result.date);
        milestone.minutes = result.minutes;
      }
      plan.sortByDate();
    });
    _store.save(plan);
  }

  Future<void> _regeneratePlan() async {
    final task = _selectedTask;
    if (task == null) return;

    // Regenerating offline would swap a real plan for generic steps
    if (context.read<AppState>().isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're in offline mode. Go online to regenerate this plan.")),
      );
      return;
    }

    if ((_plan?.doneCount ?? 0) > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Regenerate plan?'),
          content: const Text('This replaces the current steps and clears your progress on them.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Regenerate')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    _generatePlan(task);
  }

  void _openTaskPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.7),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Text('Plan a task', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                ..._activeTasks.map((t) {
                  final plan = _plans[t.id];
                  final progress = plan == null ? '' : ' • ${plan.doneCount}/${plan.milestones.length} done';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${t.courseCode} • Due ${DateFormat('E, MMM d').format(t.dueDate)}$progress'),
                    trailing: t.id == _selectedTask?.id ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _selectTask(t);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPlanFor(String taskId) {
    final task = _activeTasks.where((t) => t.id == taskId).firstOrNull;
    if (task != null) _selectTask(task);
  }

  void _openTask(Task task) {
    final course = _courses.where((c) => c.id == task.courseId).firstOrNull;
    if (course == null) return;
    context.push('/task', extra: {'course': course, 'assignment': task});
  }

  void _openDay(DateTime day) {
    showDaySheet(
      context,
      date: day,
      tasks: _activeTasks.where((t) => dateOnly(t.dueDate) == day).toList(),
      steps: [
        for (final plan in _plans.values)
          for (final m in plan.milestones)
            if (m.date == day) FocusStep(plan, m),
      ],
      onTaskTap: _openTask,
    );
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
                // View Toggle (Constrained width like the React prototype)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
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
                  ),
                ),
                Expanded(
                  child: _selectedTask == null
                      // Empty state
                      ? ListView(
                          padding: const EdgeInsets.only(bottom: 40),
                          children: [
                            _buildTodaysFocus(),
                            _buildWorkloadChart(theme),
                            if (_view == 'week') _buildWeekAtAGlance(theme) else _buildMonthGrid(theme),
                            _buildEmptyState(theme),
                          ],
                        )
                      // Populated state with ReorderableListView
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.only(bottom: 40),
                          buildDefaultDragHandles: false,
                          proxyDecorator: (Widget child, int index, Animation<double> animation) {
                            return Material(color: Colors.transparent, elevation: 0, child: child);
                          },
                          header: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTodaysFocus(),
                              _buildWorkloadChart(theme),
                              if (_view == 'week') _buildWeekAtAGlance(theme) else _buildMonthGrid(theme),
                              _buildMilestonesHeader(theme),
                            ],
                          ),
                          footer: (_isGeneratingPlan || _plan == null)
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () => _editMilestone(null),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add step'),
                                    ),
                                  ),
                                ),
                          itemCount: _isGeneratingPlan ? 0 : _milestones.length,
                          onReorderItem: (oldIndex, newIndex) {
                            final plan = _plan!;
                            // newIndex already accounts for the removed item
                            setState(() => plan.reorder(oldIndex, newIndex));
                            _store.save(plan);
                          },
                          itemBuilder: (context, index) {
                            final m = _milestones[index];
                            final isLate = !m.isDone && m.date.isBefore(_today);
                            return Padding(
                              key: ValueKey(m.id),
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
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
                                        onTap: () => _toggleMilestone(_plan!, m),
                                        child: Icon(
                                          m.isDone ? Icons.check_circle : Icons.circle_outlined,
                                          color: m.isDone ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        // Tap the step to rename, re-date or delete it
                                        child: InkWell(
                                          onTap: () => _editMilestone(m),
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
                                                '${DateFormat('E, MMM d').format(m.date)}${m.minutes != null ? ' · ~${m.minutes} min' : ''}',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: isLate ? theme.colorScheme.error : theme.colorScheme.secondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: Icon(Icons.drag_indicator, color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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

  Widget _buildTodaysFocus() {
    final today = _today;
    final soon = DateTime.now().add(const Duration(hours: 24));

    return TodaysFocusCard(
      steps: [
        for (final plan in _plans.values)
          for (final m in plan.milestones)
            if (!m.isDone && !m.date.isAfter(today)) FocusStep(plan, m),
      ],
      dueSoon: _activeTasks.where((t) => t.dueDate.isBefore(soon)).toList(),
      onToggle: (step) => _toggleMilestone(step.plan, step.milestone),
      onOpenPlan: _openPlanFor,
    );
  }

  Widget _buildWorkloadChart(ThemeData theme) {
    final today = _today;

    final List<FlSpot> spots = [];
    final List<DateTime> days = [];
    final List<int> dayCounts = [];
    final List<int> dayPoints = [];
    for (int i = 0; i < 7; i++) {
      final targetDate = DateTime(today.year, today.month, today.day + i);
      days.add(targetDate);

      int dailyCount = 0;
      int dailyPoints = 0;
      for (var t in _activeTasks) {
        if (dateOnly(t.dueDate) == targetDate) {
          dailyCount++;
          dailyPoints += t.points;
        }
      }
      dayCounts.add(dailyCount);
      dayPoints.add(dailyPoints);
      spots.add(FlSpot(i.toDouble(), dailyPoints.toDouble()));
    }

    // A day is heavy with 3+ deadlines, or 2+ worth double the week's daily average
    final avgPoints = dayPoints.fold<int>(0, (sum, p) => sum + p) / 7;
    int? heavyIndex;
    for (int i = 0; i < 7; i++) {
      final isHeavy = dayCounts[i] >= 3 || (dayCounts[i] >= 2 && dayPoints[i] >= avgPoints * 2);
      if (isHeavy && (heavyIndex == null || dayPoints[i] > dayPoints[heavyIndex])) heavyIndex = i;
    }

    String summary(int i) =>
        '${DateFormat('E').format(days[i])} · ${dayCounts[i]} ${dayCounts[i] == 1 ? 'task' : 'tasks'} · ${dayPoints[i]} pts';

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
              height: 128,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        // One label per day; without this each letter repeats at fractional positions
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (value != value.roundToDouble() || i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('E').format(days[i])[0], style: TextStyle(color: theme.colorScheme.secondary, fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchCallback: (event, response) {
                      final touched = response?.lineBarSpots;
                      if (event is FlTapUpEvent && touched != null && touched.isNotEmpty) {
                        _openDay(days[touched.first.x.toInt()]);
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.onSurface,
                      getTooltipItems: (touched) => touched
                          .map((s) => LineTooltipItem(
                                summary(s.x.toInt()),
                                TextStyle(color: theme.colorScheme.surface, fontSize: 12),
                              ))
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: theme.colorScheme.secondary.withValues(alpha: 0.6), // Soft gray line
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary.withValues(alpha: 0.4),
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
            if (heavyIndex != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Heavy day: ${summary(heavyIndex)}. Start early.',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCourseEmoji(String courseCode) {
    final emojis = ['📘', '📊', '🔬', '💻', '🎨', '📝', '🌍', '📐', '⚙️', '💡', '📚', '🚀'];

    final index = courseCode.hashCode.abs() % emojis.length;
    return emojis[index];
  }

  Widget _buildWeekAtAGlance(ThemeData theme) {
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
                  Text(_getCourseEmoji(c.courseCode), style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
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
    final firstDayOffset = DateTime(now.year, now.month, 1).weekday % 7;

    bool inThisMonth(DateTime d) => d.year == now.year && d.month == now.month;

    final Set<int> taskDays = _activeTasks.where((t) => inThisMonth(t.dueDate)).map((t) => t.dueDate.day).toSet();
    final Set<int> milestoneDays = _milestones.where((m) => inThisMonth(m.date)).map((m) => m.date.day).toSet();
    final int? dueDay = (_selectedTask != null && inThisMonth(_selectedTask!.dueDate)) ? _selectedTask!.dueDate.day : null;
    final List<String> weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

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
            // Weekday Headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays.map((d) => Expanded(
                child: Center(
                  child: Text(d, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontSize: 12))
                )
              )).toList(),
            ),
            const SizedBox(height: 8),
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
                final hasTask = taskDays.contains(day);
                final hasMilestone = milestoneDays.contains(day);

                // Other deadlines get a primary dot, planned steps a gray one
                final Color dotColor = isDue
                    ? Colors.transparent
                    : hasTask
                        ? theme.colorScheme.primary
                        : hasMilestone
                            ? theme.colorScheme.secondary
                            : Colors.transparent;

                return InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openDay(DateTime(now.year, now.month, day)),
                  child: Column(
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
                      const SizedBox(height: 2),
                      Container(
                        height: 4, width: 4,
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.calendar_month_outlined, size: 48, color: theme.colorScheme.secondary),
          const SizedBox(height: 16),
          Text('Nothing to plan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'You have no upcoming tasks. New deadlines will show up here to break into daily milestones.\n\nNote: Auto-planner only schedules current and upcoming tasks. Overdue tasks are excluded.',
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

  Widget _buildMilestonesHeader(ThemeData theme) {
    final doneCount = _plan?.doneCount ?? 0;
    final task = _selectedTask!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tap to switch which task is being planned
          Material(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _openTaskPicker,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
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
                          Text(task.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary)),
                          const SizedBox(height: 4),
                          Text(
                            '${task.courseCode} • Due ${DateFormat('E, MMM d').format(task.dueDate)}${_isGeneratingPlan ? '' : ' • ${_milestones.length} milestones'}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.unfold_more, color: theme.colorScheme.onPrimary.withValues(alpha: 0.9)),
                  ],
                ),
              ),
            ),
          ),

          if (_isGeneratingPlan)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Analyzing task and generating schedule...', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Daily milestones', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Text('$doneCount/${_milestones.length} done', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                IconButton(
                  onPressed: _regeneratePlan,
                  tooltip: 'Regenerate plan',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.refresh, size: 20, color: theme.colorScheme.secondary),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.info_outline, size: 12, color: theme.colorScheme.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Tap a step to edit it. Hold and drag the right handle to reschedule.', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
