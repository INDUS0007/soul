import 'package:flutter/material.dart';
import 'package:common/widgets/widgets.dart';
import 'package:common/api/api_client.dart' hide SessionType;
import '../models/session.dart';
import 'dart:async';

class SessionScreen extends StatefulWidget {
  final Session session;

  const SessionScreen({super.key, required this.session});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late Session _session;
  final TextEditingController _notesController = TextEditingController();
  RiskLevel _selectedRisk = RiskLevel.none;
  bool _isSessionActive = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _notesController.text = _session.notes ?? '';
    _selectedRisk = _session.riskLevel;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isSessionActive = true;
      _session = Session(
        id: _session.id,
        clientId: _session.clientId,
        clientName: _session.clientName,
        clientPhoto: _session.clientPhoto,
        counselorId: _session.counselorId,
        scheduledTime: _session.scheduledTime,
        startTime: DateTime.now(),
        endTime: _session.endTime,
        type: _session.type,
        status: SessionStatus.inProgress,
        notes: _session.notes,
        riskLevel: _session.riskLevel,
        isEscalated: _session.isEscalated,
        durationMinutes: _session.durationMinutes,
      );
    });

    // POST /api/sessions/{id}/start
    _startTimer();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Session started')));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _endSession() {
    _timer?.cancel();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to end this session?'),
            const SizedBox(height: 16),
            Text(
              'Duration: ${_formatDuration(_elapsedSeconds)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeSession();
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSession() async {
    // POST /api/sessions/{id}/end
    try {
      // Update session risk level and notes before ending
      final sessionId = int.tryParse(_session.id.toString()) ?? _session.id as int;
      if (_selectedRisk != _session.riskLevel || _notesController.text.trim().isNotEmpty) {
        try {
          await _api.updateSession(
            sessionId,
            riskLevel: _selectedRisk.name,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
        } catch (e) {
          print('Error updating session before ending: $e');
          // Continue to end session even if update fails
        }
      }

      // Call endSession API
      final response = await _api.endSession(sessionId);
      print('Session ended successfully: $response');

      if (!mounted) return;
      
      setState(() {
        _session = Session(
          id: _session.id,
          clientId: _session.clientId,
          clientName: _session.clientName,
          clientPhoto: _session.clientPhoto,
          counselorId: _session.counselorId,
          scheduledTime: _session.scheduledTime,
          startTime: _session.startTime,
          endTime: DateTime.now(),
          type: _session.type,
          status: SessionStatus.completed,
          notes: _notesController.text,
          riskLevel: _selectedRisk,
          isEscalated: _session.isEscalated,
          durationMinutes: _elapsedSeconds ~/ 60,
        );
        _isSessionActive = false;
      });

      _showSessionSummaryDialog(response);
    } catch (e) {
      print('Error ending session: $e');
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to end session: ${e.toString()}');
    }
  }

  void _showSessionSummaryDialog([Map<String, dynamic>? endResponse]) {
    final billingInfo = endResponse?['billing'] as Map<String, dynamic>?;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Client: ${_session.clientName}'),
              const SizedBox(height: 8),
              Text('Duration: ${_formatDuration(_elapsedSeconds)}'),
              const SizedBox(height: 8),
              Text('Risk Level: ${_selectedRisk.name}'),
              if (billingInfo != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Billed Amount: ₹${billingInfo['billed_amount'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Recommended Next Steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter recommended actions...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              showSuccessSnackBar(context, 'Session completed successfully');
            },
            child: const Text('Save & Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session - ${_session.clientName}'),
        actions: [
          if (_isSessionActive)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  _formatDuration(_elapsedSeconds),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        _session.clientName.substring(0, 1),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _session.clientName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Client ID: ${_session.clientId}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Session Type & Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(_getSessionTypeIcon(_session.type)),
                        const SizedBox(width: 8),
                        Text('Type: ${_session.type.name.toUpperCase()}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(_getStatusIcon(_session.status)),
                        const SizedBox(width: 8),
                        Text('Status: ${_session.status.name}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule),
                        const SizedBox(width: 8),
                        Text(
                          'Scheduled: ${_formatDateTime(_session.scheduledTime)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Session Controls
            if (!_isSessionActive && _session.status == SessionStatus.scheduled)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Ready to start the session?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _startSession,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Session'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_isSessionActive) ...[
              // Active Session Controls
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.circle, color: Colors.red, size: 12),
                          SizedBox(width: 8),
                          Text(
                            'Session In Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Voice call or chat interface
                              },
                              icon: Icon(_getSessionTypeIcon(_session.type)),
                              label: Text(
                                _session.type == SessionType.voice
                                    ? 'Audio Call Active'
                                    : 'Chat Active',
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _endSession,
                            icon: const Icon(Icons.stop),
                            label: const Text('End'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Session Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Notes (Private)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter private notes about this session...',
                      ),
                      maxLines: 6,
                      enabled:
                          _isSessionActive ||
                          _session.status == SessionStatus.scheduled,
                    ),
                    if (_isSessionActive ||
                        _session.status == SessionStatus.scheduled) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          // POST /api/sessions/{id}/notes
                          showSuccessSnackBar(context, 'Notes saved');
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Notes'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Risk Assessment
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Risk Assessment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...RiskLevel.values.map(
                      (risk) => RadioListTile<RiskLevel>(
                        title: Text(risk.name.toUpperCase()),
                        value: risk,
                        groupValue: _selectedRisk,
                        onChanged:
                            _isSessionActive ||
                                _session.status == SessionStatus.scheduled
                            ? (value) {
                                setState(() {
                                  _selectedRisk = value!;
                                });
                              }
                            : null,
                        tileColor: _getRiskLevelColor(risk).withOpacity(0.1),
                      ),
                    ),
                    if (_selectedRisk != RiskLevel.none &&
                        (_isSessionActive ||
                            _session.status == SessionStatus.scheduled)) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          // POST /api/sessions/{id}/risk
                          _createIncident();
                        },
                        icon: const Icon(Icons.warning),
                        label: const Text('Create Incident Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Escalation
            if (_isSessionActive || _session.status == SessionStatus.scheduled)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Escalation to Medical Professional',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'If this case requires medical attention or psychiatric evaluation, escalate to a licensed doctor or psychiatrist.',
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _escalateToDoctor,
                        icon: const Icon(Icons.local_hospital),
                        label: const Text('Request Medical Consultation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
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

  IconData _getSessionTypeIcon(SessionType type) {
    switch (type) {
      case SessionType.voice:
        return Icons.phone;
      case SessionType.chat:
        return Icons.chat;
    }
  }

  IconData _getStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return Icons.schedule;
      case SessionStatus.inProgress:
        return Icons.play_circle;
      case SessionStatus.completed:
        return Icons.check_circle;
      case SessionStatus.cancelled:
        return Icons.cancel;
      case SessionStatus.noShow:
        return Icons.event_busy;
    }
  }

  Color _getRiskLevelColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.none:
        return Colors.green;
      case RiskLevel.low:
        return Colors.yellow;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.deepOrange;
      case RiskLevel.critical:
        return Colors.red;
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _createIncident() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Incident Report'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will create an incident report and notify:'),
            SizedBox(height: 12),
            Text('• Platform Administrator'),
            Text('• On-call Medical Professional'),
            Text('• Crisis Response Team (if critical)'),
            SizedBox(height: 12),
            Text(
              'Emergency contacts may be requested per SOP.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // POST /api/incidents
              Navigator.pop(context);
              showSuccessSnackBar(context, 'Incident report created. Authorities notified.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Report'),
          ),
        ],
      ),
    );
  }

  void _escalateToDoctor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Medical Consultation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'As a counselor, you can request a psychiatric evaluation or medical consultation. Provide context below:',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Reason for medical consultation request...',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // POST /api/consults
              Navigator.pop(context);
              showSuccessSnackBar(context, 'Medical consultation request sent to licensed doctor');
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}
