import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';
import 'schedule_session_page.dart';

class UpcomingSessionsPage extends StatefulWidget {
  const UpcomingSessionsPage({super.key});

  @override
  State<UpcomingSessionsPage> createState() => _UpcomingSessionsPageState();
}

class _UpcomingSessionsPageState extends State<UpcomingSessionsPage> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  List<UpcomingSessionItem> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }

    try {
      final sessions = await _api.fetchUpcomingSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
        _refreshing = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
        _refreshing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load sessions. Please try again. ($error)';
        _loading = false;
        _refreshing = false;
      });
    }
  }

  Future<void> _handleRefresh() => _loadSessions(showLoader: false);

  Future<void> _openCreateDialog({UpcomingSessionItem? session}) async {
    final now = DateTime.now().add(const Duration(hours: 1));
    final titleController = TextEditingController(text: session?.title ?? '');
    final counsellorController =
        TextEditingController(text: session?.counsellorName ?? '');
    final notesController = TextEditingController(text: session?.notes ?? '');
    SessionType sessionType = session?.sessionType ?? SessionType.oneOnOne;
    DateTime selectedDateTime = session?.startTime ?? now;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(session == null ? 'Book Session' : 'Update Session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SessionType>(
                      value: sessionType,
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => sessionType = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Session Type',
                        border: OutlineInputBorder(),
                      ),
                      items: SessionType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.displayLabel),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: counsellorController,
                      decoration: const InputDecoration(
                        labelText: 'Counsellor Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              DateFormat('EEE, MMM d').format(selectedDateTime),
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                initialDate: selectedDateTime,
                              );
                              if (date != null) {
                                setModalState(() {
                                  selectedDateTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    selectedDateTime.hour,
                                    selectedDateTime.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              DateFormat('h:mm a').format(selectedDateTime),
                            ),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                              );
                              if (time != null) {
                                setModalState(() {
                                  selectedDateTime = DateTime(
                                    selectedDateTime.year,
                                    selectedDateTime.month,
                                    selectedDateTime.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(session == null ? 'Book' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      titleController.dispose();
      counsellorController.dispose();
      notesController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final counsellor = counsellorController.text.trim();
    final notes = notesController.text.trim();

    titleController.dispose();
    counsellorController.dispose();
    notesController.dispose();

    if (title.isEmpty || counsellor.isEmpty) {
      showErrorSnackBar(context, 'Please fill in the title and counsellor name.');
      return;
    }

    try {
      if (session == null) {
        final created = await _api.createUpcomingSession(
          title: title,
          sessionType: sessionType,
          startTime: selectedDateTime,
          counsellorName: counsellor,
          notes: notes.isNotEmpty ? notes : null,
        );
        if (!mounted) return;
        setState(() {
          _sessions = [..._sessions, created]..sort(
              (a, b) => a.startTime.compareTo(b.startTime),
            );
        });
        showSuccessSnackBar(context, 'Session booked successfully!');
      } else {
        final updated = await _api.updateUpcomingSession(
          sessionId: session.id,
          title: title,
          sessionType: sessionType,
          startTime: selectedDateTime,
          counsellorName: counsellor,
          notes: notes,
        );
        if (!mounted) return;
        setState(() {
          _sessions = [
            for (final item in _sessions)
              if (item.id == session.id) updated else item,
          ]..sort((a, b) => a.startTime.compareTo(b.startTime));
        });
        showSuccessSnackBar(context, 'Session updated!');
      }
    } on ApiClientException catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, error.message);
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Something went wrong. Please try again. ($error)');
    }
  }

  Future<void> _deleteSession(UpcomingSessionItem session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel session?'),
        content: Text('Are you sure you want to remove "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.deleteUpcomingSession(session.id);
      if (!mounted) return;
      setState(() {
        _sessions = _sessions.where((item) => item.id != session.id).toList();
      });
      showSuccessSnackBar(context, 'Session cancelled.');
    } on ApiClientException catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, error.message);
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Unable to cancel session. Please try again. ($error)');
    }
  }

  Future<void> _openSchedulePage() async {
    final result = await Navigator.push<UpcomingSessionItem>(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleSessionPage()),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _sessions = [..._sessions, result]
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      });
      showSuccessSnackBar(context, 'Session booked successfully!');
    } else {
      await _loadSessions(showLoader: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Upcoming Sessions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5FBF),
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSchedulePage,
        backgroundColor: const Color(0xFF8B5FBF),
        icon: const Icon(Icons.add),
        label: const Text('Book Session'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && !_refreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadSessions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildEmptyState(),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                children: [
                  for (final session in _sessions) ...[
                    _buildSessionCard(session),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5FBF), Color(0xFF9E8BE3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Wellness Journey Ahead',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _sessions.isEmpty
                ? 'You have no upcoming sessions. Book one to get started.'
                : 'You have ${_sessions.length} upcoming ${_sessions.length == 1 ? 'session' : 'sessions'}.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.event_available,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'No Upcoming Sessions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Book a session to start your wellness journey',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _openSchedulePage,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5FBF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Schedule Now'),
        ),
      ],
    );
  }

  Widget _buildSessionCard(UpcomingSessionItem session) {
    final now = DateTime.now();
    final isToday = session.startTime.day == now.day &&
        session.startTime.month == now.month &&
        session.startTime.year == now.year;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = session.startTime.day == tomorrow.day &&
        session.startTime.month == tomorrow.month &&
        session.startTime.year == tomorrow.year;

    String getDateText() {
      if (isToday) return 'Today';
      if (isTomorrow) return 'Tomorrow';
      return DateFormat('E, MMM d').format(session.startTime);
    }

    IconData getTypeIcon() {
      switch (session.sessionType) {
        case SessionType.oneOnOne:
          return Icons.person;
        case SessionType.group:
          return Icons.group;
        case SessionType.workshop:
          return Icons.school;
        case SessionType.webinar:
          return Icons.wifi;
      }
    }

    Color getTypeColor() {
      switch (session.sessionType) {
        case SessionType.oneOnOne:
          return Colors.blue;
        case SessionType.group:
          return Colors.green;
        case SessionType.workshop:
          return Colors.orange;
        case SessionType.webinar:
          return Colors.purple;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getTypeIcon(),
                    color: getTypeColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        session.sessionType.displayLabel,
                        style: TextStyle(
                          color: getTypeColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openCreateDialog(session: session);
                    } else if (value == 'delete') {
                      _deleteSession(session);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  getDateText(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('h:mm a').format(session.startTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  session.counsellorName,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (session.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                session.notes,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _openCreateDialog(session: session),
                  child: const Text('Reschedule'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    showSuccessSnackBar(context, 'Join session link will open soon.');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5FBF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Join Session'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


