// Bottom sheet for adding or editing a single plan milestone.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/milestone.dart';

class MilestoneEdit {
  final String title;
  final DateTime date;
  final int? minutes;
  final bool delete;

  const MilestoneEdit({required this.title, required this.date, this.minutes, this.delete = false});
}

Future<MilestoneEdit?> showMilestoneEditor(
  BuildContext context, {
  Milestone? milestone,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showModalBottomSheet<MilestoneEdit>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _MilestoneEditorSheet(milestone: milestone, firstDate: firstDate, lastDate: lastDate),
  );
}

class _MilestoneEditorSheet extends StatefulWidget {
  final Milestone? milestone;
  final DateTime firstDate;
  final DateTime lastDate;

  const _MilestoneEditorSheet({this.milestone, required this.firstDate, required this.lastDate});

  @override
  State<_MilestoneEditorSheet> createState() => _MilestoneEditorSheetState();
}

class _MilestoneEditorSheetState extends State<_MilestoneEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _minutesController;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.milestone?.title ?? '');
    _minutesController = TextEditingController(text: widget.milestone?.minutes?.toString() ?? '');
    _date = widget.milestone?.date ?? widget.firstDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final first = _date.isBefore(widget.firstDate) ? _date : widget.firstDate;
    final last = _date.isAfter(widget.lastDate) ? _date : widget.lastDate;

    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: first, lastDate: last);
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final minutes = int.tryParse(_minutesController.text.trim());
    Navigator.pop(
      context,
      MilestoneEdit(title: title, date: _date, minutes: (minutes != null && minutes > 0) ? minutes : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.milestone != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEditing ? 'Edit step' : 'Add step', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: !isEditing,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'What to do'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(DateFormat('E, MMM d').format(_date)),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minutes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (isEditing)
                TextButton.icon(
                  onPressed: () => Navigator.pop(
                    context,
                    MilestoneEdit(title: widget.milestone!.title, date: _date, delete: true),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
