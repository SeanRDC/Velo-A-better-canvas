// Local persistence for study plans, keyed by Canvas task id.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/milestone.dart';

class PlannerStore {
  static const String _key = 'planner_plans_v1';

  SharedPreferences? _cachedPrefs;
  Future<SharedPreferences> get _prefs async => _cachedPrefs ??= await SharedPreferences.getInstance();

  Future<Map<String, StudyPlan>> loadAll() async {
    final raw = (await _prefs).getString(_key);
    if (raw == null) return {};

    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((id, plan) => MapEntry(id, StudyPlan.fromJson(plan as Map<String, dynamic>)));
    } catch (e) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, StudyPlan> plans) async {
    await (await _prefs).setString(_key, jsonEncode(plans.map((id, plan) => MapEntry(id, plan.toJson()))));
  }

  Future<void> save(StudyPlan plan) async {
    final plans = await loadAll();
    plans[plan.taskId] = plan;
    await _writeAll(plans);
  }

  Future<void> delete(String taskId) async {
    final plans = await loadAll();
    plans.remove(taskId);
    await _writeAll(plans);
  }

  Future<Map<String, StudyPlan>> prune(Set<String> activeTaskIds) async {
    final plans = await loadAll();
    final before = plans.length;
    plans.removeWhere((id, _) => !activeTaskIds.contains(id));
    if (plans.length != before) await _writeAll(plans);
    return plans;
  }
}
