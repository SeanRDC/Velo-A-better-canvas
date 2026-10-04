// Tests for saved study plans and milestone rescheduling
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:final_project/models/milestone.dart';
import 'package:final_project/services/planner_store.dart';

StudyPlan _plan(String taskId) {
  return StudyPlan(
    taskId: taskId,
    taskTitle: 'Essay $taskId',
    courseCode: 'ENG101',
    dueDate: DateTime(2026, 10, 9, 23, 59),
    milestones: [
      Milestone(id: '$taskId-m0', title: 'Outline', date: DateTime(2026, 10, 5), minutes: 30),
      Milestone(id: '$taskId-m1', title: 'Draft', date: DateTime(2026, 10, 7), minutes: 90),
      Milestone(id: '$taskId-m2', title: 'Revise', date: DateTime(2026, 10, 9)),
    ],
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saved plans round-trip with progress intact', () async {
    final plan = _plan('1');
    plan.milestones[0].isDone = true;
    await PlannerStore().save(plan);

    final loaded = (await PlannerStore().loadAll())['1']!;
    expect(loaded.taskTitle, 'Essay 1');
    expect(loaded.dueDate, DateTime(2026, 10, 9, 23, 59));
    expect(loaded.milestones.map((m) => m.title), ['Outline', 'Draft', 'Revise']);
    expect(loaded.milestones[0].isDone, isTrue);
    expect(loaded.milestones[1].minutes, 90);
    expect(loaded.milestones[2].minutes, isNull);
    expect(loaded.doneCount, 1);
  });

  test('prune drops plans for tasks that are no longer active', () async {
    final store = PlannerStore();
    await store.save(_plan('1'));
    await store.save(_plan('2'));

    final kept = await store.prune({'2'});
    expect(kept.keys, ['2']);
    expect((await store.loadAll()).keys, ['2']);
  });

  test('delete removes a single plan', () async {
    final store = PlannerStore();
    await store.save(_plan('1'));
    await store.delete('1');
    expect(await store.loadAll(), isEmpty);
  });

  test('unreadable saved data loads as no plans', () async {
    SharedPreferences.setMockInitialValues({'planner_plans_v1': 'not json'});
    expect(await PlannerStore().loadAll(), isEmpty);
  });

  test('reorder moves the step and keeps the dates in their slots', () {
    final plan = _plan('1');
    plan.reorder(0, 2); // Drag "Outline" to the end

    expect(plan.milestones.map((m) => m.title), ['Draft', 'Revise', 'Outline']);
    expect(plan.milestones.map((m) => m.date), [DateTime(2026, 10, 5), DateTime(2026, 10, 7), DateTime(2026, 10, 9)]);
  });

  test('sortByDate orders steps and keeps same-day order stable', () {
    final plan = _plan('1');
    plan.milestones.add(Milestone(id: '1-m3', title: 'Read rubric', date: DateTime(2026, 10, 5)));
    plan.milestones[1].date = DateTime(2026, 10, 4);
    plan.sortByDate();

    expect(plan.milestones.map((m) => m.title), ['Draft', 'Outline', 'Read rubric', 'Revise']);
  });
}
