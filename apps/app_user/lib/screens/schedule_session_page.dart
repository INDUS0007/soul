import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';

class ScheduleSessionPage extends StatefulWidget {
  const ScheduleSessionPage({super.key});

  @override
  State<ScheduleSessionPage> createState() => _ScheduleSessionPageState();
}

class _ScheduleSessionPageState extends State<ScheduleSessionPage> {
  final ApiClient _api = ApiClient();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _titleCtrl =
      TextEditingController(text: 'Counselling Session');

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final recommended = DateTime.now().add(const Duration(hours: 1));
    _selectedDate = DateTime(recommended.year, recommended.month, recommended.day);
    _selectedTime = TimeOfDay(hour: recommended.hour, minute: recommended.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF8B5FBF)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ??
          TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF8B5FBF)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveSession() async {
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) {
      showErrorSnackBar(context, 'Please select a date and a time.');
      return;
    }

    final start = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final now = DateTime.now();
    final earliestAllowed = now.add(const Duration(minutes: 10));
    final recommended = now.add(const Duration(hours: 1));

    if (start.isBefore(earliestAllowed)) {
      showErrorSnackBar(context, 'Please choose a time at least 10 minutes from now.');
      return;
    }

    if (start.isBefore(recommended)) {
      final confirm = await _confirmEarlySession(start, recommended);
      if (confirm != true) {
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final session = await _api.scheduleQuickSession(
        start,
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );
      if (!mounted) return;

      final formatted =
          DateFormat('dd MMM yyyy • h:mm a').format(session.startTime.toLocal());

      showSuccessSnackBar(context, 'Session scheduled for $formatted');
      Navigator.pop(context, session);
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Could not schedule session: $error');
      setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmEarlySession(DateTime start, DateTime recommended) {
    final formatter = DateFormat('dd MMM, h:mm a');
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule earlier than recommended?'),
        content: Text(
          'We usually suggest booking at least 1 hour ahead. '
          'You selected ${formatter.format(start.toLocal())}, which is sooner than the suggested '
          '${formatter.format(recommended.toLocal())}. Proceed anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Pick another time'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Schedule anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.titleLarge?.copyWith(
      color: const Color(0xFF8B5FBF),
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Schedule Session'),
        backgroundColor: const Color(0xFF8B5FBF),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan your counselling session',
                style: headline,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a convenient date, time, and leave a note for your counsellor.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              _FormCard(
                children: [
                  _InputLabel(title: 'Session title'),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Counselling Session',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InputLabel(title: 'Date'),
                  _SelectorButton(
                    label: _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'Select date',
                    icon: Icons.calendar_today,
                    onPressed: _pickDate,
                  ),
                  const SizedBox(height: 20),
                  _InputLabel(title: 'Time'),
                  _SelectorButton(
                    label: _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Select time',
                    icon: Icons.access_time,
                    onPressed: _pickTime,
                  ),
              const SizedBox(height: 6),
              Text(
                'Tip: Sessions are best scheduled at least 1 hour ahead, '
                'but you can still start as soon as 10 minutes from now.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
                  const SizedBox(height: 20),
                  _InputLabel(title: 'Notes for your counsellor (optional)'),
                  TextField(
                    controller: _notesCtrl,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Let us know anything important before the session',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5FBF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Add New Event',
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year.toString()}';
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  const _SelectorButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5FBF).withOpacity(0.08),
        foregroundColor: const Color(0xFF8B5FBF),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Icon(icon),
        ],
      ),
    );
  }
}

