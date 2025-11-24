import 'package:flutter/material.dart';
import 'package:common/widgets/widgets.dart';
import '../main.dart';
import '../models/availability.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final Map<String, List<TimeSlot>> _weeklySchedule = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  final List<DateTime> _blockedDates = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    // Mock data - replace with API call GET /api/providers/{id}/availability
    setState(() {
      _weeklySchedule['Monday'] = [
        TimeSlot(
          startTime: DateTime(2024, 1, 1, 9, 0),
          endTime: DateTime(2024, 1, 1, 12, 0),
          isAvailable: true,
        ),
        TimeSlot(
          startTime: DateTime(2024, 1, 1, 14, 0),
          endTime: DateTime(2024, 1, 1, 17, 0),
          isAvailable: true,
        ),
      ];
      _weeklySchedule['Wednesday'] = [
        TimeSlot(
          startTime: DateTime(2024, 1, 1, 10, 0),
          endTime: DateTime(2024, 1, 1, 16, 0),
          isAvailable: true,
        ),
      ];
      _weeklySchedule['Friday'] = [
        TimeSlot(
          startTime: DateTime(2024, 1, 1, 9, 0),
          endTime: DateTime(2024, 1, 1, 13, 0),
          isAvailable: true,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAvailability,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Set your weekly availability schedule. Clients will only be able to book during these times.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Weekly Schedule
            Text(
              'Weekly Schedule',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ..._weeklySchedule.entries.map((entry) {
              return _buildDayCard(entry.key, entry.value);
            }),

            const SizedBox(height: 24),

            // Blocked Dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Blocked Dates (PTO)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addBlockedDate,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_blockedDates.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No blocked dates',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._blockedDates.map(
                (date) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.event_busy, color: Colors.red),
                    title: Text(_formatDate(date)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _blockedDates.remove(date);
                        });
                      },
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Calendar Integration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calendar Integration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sync your availability with external calendars',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Google Calendar sync
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Google Calendar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Outlook sync
                            },
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('Outlook'),
                          ),
                        ),
                      ],
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

  Widget _buildDayCard(String day, List<TimeSlot> slots) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          slots.isEmpty ? 'Unavailable' : '${slots.length} time slot(s)',
          style: TextStyle(
            color: slots.isEmpty ? Colors.red : Colors.green,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _addTimeSlot(day),
        ),
        children: [
          if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No availability set for this day',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...slots.map(
              (slot) => ListTile(
                leading: Icon(
                  slot.isAvailable ? Icons.access_time : Icons.block,
                  color: slot.isAvailable ? Colors.green : Colors.red,
                ),
                title: Text(
                  '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editTimeSlot(day, slot),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _weeklySchedule[day]?.remove(slot);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _addTimeSlot(String day) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Time Slot - $day'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(startTime?.format(context) ?? 'Not selected'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (time != null) {
                    setDialogState(() {
                      startTime = time;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(endTime?.format(context) ?? 'Not selected'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 17, minute: 0),
                  );
                  if (time != null) {
                    setDialogState(() {
                      endTime = time;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: startTime != null && endTime != null
                  ? () {
                      setState(() {
                        _weeklySchedule[day]?.add(
                          TimeSlot(
                            startTime: DateTime(
                              2024,
                              1,
                              1,
                              startTime!.hour,
                              startTime!.minute,
                            ),
                            endTime: DateTime(
                              2024,
                              1,
                              1,
                              endTime!.hour,
                              endTime!.minute,
                            ),
                            isAvailable: true,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editTimeSlot(String day, TimeSlot slot) {
    // Similar to add, but with pre-filled values
    _addTimeSlot(day);
  }

  void _addBlockedDate() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        setState(() {
          _blockedDates.add(date);
        });
      }
    });
  }

  void _saveAvailability() {
    // PUT /api/providers/{id}/availability
    // Convert to JSON and send to API
    final availabilityData = Availability(
      counselorId: 'counselor_1',
      weeklySchedule: _weeklySchedule,
      blockedDates: _blockedDates,
    ).toJson();

    // Send availabilityData to API
    appLogger.debug('Saving availability: $availabilityData');

    showSuccessSnackBar(context, 'Availability saved successfully');
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
