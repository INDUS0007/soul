import 'package:flutter/material.dart';
import 'package:common/api/api_client.dart' hide SessionType;
import 'package:common/widgets/widgets.dart';
import '../models/counselor.dart';
import '../models/session.dart';
import '../widgets/counsellor_quick_info_widget.dart';
import '../utils/responsive.dart';
import 'profile_setup_screen.dart';
import 'appointments_screen.dart';
import 'chat_session_screen.dart';
import 'queued_chats_screen.dart';
import 'audio_call_screen.dart';
import 'availability_screen.dart';
import 'client_records_screen.dart';
import 'performance_screen.dart';
import 'login_screen.dart';
import 'dart:async';

class CounselorDashboard extends StatefulWidget {
  const CounselorDashboard({super.key});

  @override
  State<CounselorDashboard> createState() => _CounselorDashboardState();
}

class _CounselorDashboardState extends State<CounselorDashboard> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  Counselor? counselor;
  List<Session> upcomingSessions = [];
  Map<String, dynamic>? _stats;
  int pendingVerifications = 0;
  int queuedChats = 0;
  Map<String, dynamic>? _nextClientInfo;
  List<Map<String, dynamic>> _queuedChatsList = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 60 seconds (reduced from 30 to reduce log noise)
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load counselor profile
      final profileData = await _api.getCounsellorProfile();
      
      // Load appointments
      final appointmentsData = await _api.getCounsellorAppointments(status: 'upcoming');
      
      // Load stats
      final statsData = await _api.getCounsellorStats();

      // Load queued chats with error handling
      List<Map<String, dynamic>> queuedChatsData = [];
      try {
        print('[Dashboard] Fetching queued chats from API...');
        queuedChatsData = await _api.getQueuedChats();
        print('[Dashboard] Queued chats loaded successfully: ${queuedChatsData.length}');
        if (queuedChatsData.isNotEmpty) {
          print('[Dashboard] Queued chats data: $queuedChatsData');
        } else {
          print('[Dashboard] No queued chats found. Checking if chats exist in database...');
        }
      } catch (e, stackTrace) {
        print('[Dashboard] Error loading queued chats: $e');
        print('[Dashboard] Stack trace: $stackTrace');
        // Continue with empty list - don't break the whole dashboard
      }

      if (!mounted) return;

      // Convert profile data to Counselor model
      counselor = Counselor(
        id: profileData['id']?.toString() ?? '0',
        name: profileData['full_name'] ?? profileData['username'] ?? 'Counselor',
        email: profileData['email'] ?? '',
        specialization: profileData['specialization'] ?? '',
        bio: profileData['bio'],
        photoUrl: null,
        certifications: [],
        isVerified: true,
        rating: _parseDouble(profileData['rating']),
        totalSessions: statsData['total_sessions'] ?? 0,
      );

      // Convert appointments to Session models
      upcomingSessions = appointmentsData.map((appointment) {
        return Session(
          id: appointment['id']?.toString() ?? '',
          clientId: appointment['client_username'] ?? '',
          clientName: appointment['client_name'] ?? 'Client',
          counselorId: counselor?.id ?? '',
          scheduledTime: DateTime.parse(appointment['start_time']),
          type: _parseSessionType(appointment['session_type']),
          status: SessionStatus.scheduled,
          durationMinutes: 60,
        );
      }).toList();

      _stats = statsData;
      pendingVerifications = 0; // Can be updated based on backend
      // Always use actual API response length for accuracy
      queuedChats = queuedChatsData.length;
      _queuedChatsList = queuedChatsData;
      print('[Dashboard] Queued chats count: $queuedChats (from API: ${queuedChatsData.length}, from stats: ${statsData['queued_chats']})');

      // Extract client info from the next upcoming session or queued chat
      if (upcomingSessions.isNotEmpty) {
        final nextSession = upcomingSessions.first;
        _nextClientInfo = {
          'userId': nextSession.clientId,
          'displayName': nextSession.clientName,
          'sessionType': nextSession.type.name,
          'scheduledTime': nextSession.scheduledTime,
        };
      } else if (_queuedChatsList.isNotEmpty) {
        // Show first queued chat if no upcoming sessions
        final queuedChat = _queuedChatsList.first;
        final chatIdRaw = queuedChat['id'];
        final chatId = chatIdRaw is int 
            ? chatIdRaw 
            : (chatIdRaw is String 
                ? int.tryParse(chatIdRaw) 
                : null);
        _nextClientInfo = {
          'userId': queuedChat['user_username'] ?? queuedChat['user']?.toString() ?? 'N/A',
          'displayName': queuedChat['user_name'] ?? queuedChat['user_username'] ?? 'Client',
          'sessionType': 'chat',
          'isQueued': true,
          'chatId': chatId,
          'initialMessage': queuedChat['initial_message'],
        };
      } else {
        _nextClientInfo = null;
      }

      setState(() {
        _loading = false;
      });
    } on ApiClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load data: $e';
      });
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }

  SessionType _parseSessionType(String? type) {
    switch (type) {
      case 'one_on_one':
        return SessionType.voice;
      case 'group':
      case 'workshop':
      case 'webinar':
        return SessionType.chat;
      default:
        return SessionType.voice;
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _api.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || counselor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Failed to load data'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _handleLogout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counselor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileSetupScreen(counselor: counselor!),
                  ),
                );
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
              vertical: 12,
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(),
              const SizedBox(height: 16),

              // Client Quick Info - Show for next upcoming session or queued chat
              if (_nextClientInfo != null)
                GestureDetector(
                  onTap: _nextClientInfo!['isQueued'] == true
                      ? () => _handleAcceptQueuedChat(_nextClientInfo!['chatId'])
                      : null,
                  child: CounsellorQuickInfoWidget(
                    userId: _nextClientInfo!['userId'] ?? 'N/A',
                    displayName: _nextClientInfo!['displayName'] ?? 'Client',
                    age: 0, // Age not available from appointment data
                    issueReason: _nextClientInfo!['isQueued'] == true
                        ? (_nextClientInfo!['initialMessage'] ?? 'Queued chat waiting for acceptance')
                        : 'Upcoming ${_nextClientInfo!['sessionType']} session scheduled',
                    languagePreference: 'English', // Default, can be enhanced with user profile data
                  ),
                ),
              if (_nextClientInfo != null && _nextClientInfo!['isQueued'] == true)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAcceptQueuedChat(_nextClientInfo!['chatId']),
                    icon: const Icon(Icons.chat),
                    label: const Text('Accept Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              if (_nextClientInfo != null) const SizedBox(height: 20),

              // Quick Stats
              _buildQuickStats(),
              const SizedBox(height: 20),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.heading2(context),
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 20),

              // Upcoming Sessions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Sessions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.heading2(context),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppointmentsScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildUpcomingSessions(),
              const SizedBox(height: 20),

              // Queued Chats Section
              if (_queuedChatsList.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Queued Chats',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.heading2(context),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QueuedChatsScreen(),
                          ),
                        ).then((_) {
                          // Refresh data when returning
                          _loadData();
                        });
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQueuedChats(),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 20), // Bottom padding for safer scrolling
            ],
          ),
        ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Stats',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AvailabilityScreen(),
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClientRecordsScreen(),
                ),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PerformanceScreen(),
                ),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: Responsive.isMobile(context) ? 30 : 35,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                   child: counselor!.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            counselor!.photoUrl!,
                            width: Responsive.isMobile(context) ? 60 : 70,
                            height: Responsive.isMobile(context) ? 60 : 70,
                            fit: BoxFit.cover,
                          ),
                        )
                        : Text(
                           counselor!.name.substring(0, 1),
                          style: TextStyle(
                            fontSize: Responsive.isMobile(context) ? 24 : 28,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: Responsive.caption(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                        Text(
                         counselor!.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.isMobile(context) ? 16 : 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                               '${counselor!.rating} • ${counselor!.totalSessions} sessions',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: Responsive.caption(context),
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
             if (counselor!.isVerified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
              child: _buildStatCard(
              'Today\'s Sessions',
              '${_stats?['today_sessions'] ?? upcomingSessions.where((s) => s.scheduledTime.day == DateTime.now().day).length}',
            Icons.event_available,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QueuedChatsScreen(),
                ),
              ).then((_) {
                // Refresh data when returning
                _loadData();
              });
            },
            borderRadius: BorderRadius.circular(12),
          child: _buildStatCard(
            'Queued Chats',
            '$queuedChats',
            Icons.chat_bubble_outline,
            Colors.purple,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending Tasks',
            '$pendingVerifications',
            Icons.assignment_outlined,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: Responsive.isMobile(context) ? 28 : 32,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.isMobile(context) ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.isMobile(context) ? 10 : 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3, // Always 3 columns for mobile-first design
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: Responsive.isMobile(context) ? 0.95 : 1.1,
      children: [
        _buildActionButton(
          'Manage\nSchedule',
          Icons.calendar_month,
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AvailabilityScreen(),
              ),
            );
          },
        ),
        _buildActionButton('View\nClients', Icons.people, Colors.green, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClientRecordsScreen(),
            ),
          );
        }),
        _buildActionButton('Block\nTime Off', Icons.event_busy, Colors.red, () {
          _showBlockTimeDialog();
        }),
        _buildActionButton('My\nProfile', Icons.person, Colors.purple, () {
          Navigator.push(
            context,
            MaterialPageRoute(
                  builder: (context) => ProfileSetupScreen(counselor: counselor!),
            ),
          );
        }),
        _buildActionButton('Performance', Icons.analytics, Colors.orange, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PerformanceScreen()),
          );
        }),
        _buildActionButton('Support', Icons.help_outline, Colors.teal, () {
          // Show support dialog
        }),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(Responsive.isMobile(context) ? 8 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: Responsive.isMobile(context) ? 28 : 32,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.isMobile(context) ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSessions() {
    if (upcomingSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(Responsive.isMobile(context) ? 24 : 32),
          child: Column(
            children: [
              Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No upcoming sessions',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Responsive.body(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: upcomingSessions.take(3).map((session) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          child: ListTile(
            contentPadding: EdgeInsets.all(
              Responsive.isMobile(context) ? 12 : 16,
            ),
            leading: CircleAvatar(
              radius: Responsive.isMobile(context) ? 24 : 28,
              backgroundColor: _getSessionTypeColor(
                session.type,
              ).withOpacity(0.2),
              child: Icon(
                _getSessionTypeIcon(session.type),
                color: _getSessionTypeColor(session.type),
                size: Responsive.isMobile(context) ? 20 : 24,
              ),
            ),
            title: Text(
              session.clientName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.body(context),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _formatSessionTime(session.scheduledTime),
                  style: TextStyle(fontSize: Responsive.caption(context)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getSessionTypeColor(
                          session.type,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session.type.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: Responsive.isMobile(context) ? 9 : 10,
                          fontWeight: FontWeight.bold,
                          color: _getSessionTypeColor(session.type),
                        ),
                      ),
                    ),
                    Text(
                      '${session.durationMinutes} min',
                      style: TextStyle(
                        fontSize: Responsive.caption(context),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // Navigate to appropriate session screen based on type
                if (session.type == SessionType.chat) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatSessionScreen(session: session),
                    ),
                  );
                } else if (session.type == SessionType.voice) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AudioCallScreen(session: session),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Start'),
            ),
          ),
        );
      }).toList(),
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

  Color _getSessionTypeColor(SessionType type) {
    switch (type) {
      case SessionType.voice:
        return Colors.green;
      case SessionType.chat:
        return Colors.purple;
    }
  }

  String _formatSessionTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours} hours';
    } else {
      return 'Tomorrow at ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  Widget _buildQueuedChats() {
    if (_queuedChatsList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No queued chats',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _queuedChatsList.map((chat) {
        // Ensure chatId is an int
        final chatIdRaw = chat['id'];
        final chatId = chatIdRaw is int 
            ? chatIdRaw 
            : (chatIdRaw is String 
                ? int.tryParse(chatIdRaw) 
                : null);
        final userName = chat['user_name'] ?? chat['user_username'] ?? 'Client';
        final initialMessage = chat['initial_message']?.toString() ?? 'No initial message';
        final createdAt = chat['created_at'] != null
            ? DateTime.tryParse(chat['created_at'].toString())
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          child: ListTile(
            contentPadding: EdgeInsets.all(
              Responsive.isMobile(context) ? 12 : 16,
            ),
            leading: CircleAvatar(
              radius: Responsive.isMobile(context) ? 24 : 28,
              backgroundColor: Colors.purple.withOpacity(0.2),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.purple,
              ),
            ),
            title: Text(
              userName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.body(context),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  initialMessage.length > 50
                      ? '${initialMessage.substring(0, 50)}...'
                      : initialMessage,
                  style: TextStyle(fontSize: Responsive.caption(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Received: ${_formatTime(createdAt)}',
                    style: TextStyle(
                      fontSize: Responsive.caption(context),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            trailing: ElevatedButton(
              onPressed: chatId != null 
                  ? () => _handleAcceptQueuedChat(chatId)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleAcceptQueuedChat(int? chatId) async {
    if (chatId == null) return;

    try {
      final chatData = await _api.acceptChat(chatId);
      
      if (!mounted) return;

      // Create a session from the accepted chat
      final now = DateTime.now();
      final session = Session(
        id: chatId.toString(),
        clientId: chatData['user_username'] ?? chatData['user']?.toString() ?? '',
        clientName: chatData['user_name'] ?? chatData['user_username'] ?? 'Client',
        counselorId: counselor?.id ?? '',
        scheduledTime: now,
        startTime: now, // Set start time immediately
        type: SessionType.chat,
        status: SessionStatus.inProgress,
        durationMinutes: 60,
        notes: chatData['initial_message']?.toString(), // Store initial message in notes for now
      );

      // Navigate to chat session
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatSessionScreen(session: session),
        ),
      ).then((_) {
        // Refresh data when returning from chat
        _loadData();
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to accept chat: $e');
    }
  }

  void _showBlockTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Time Off'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select dates to block for PTO or unavailability.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Show date picker
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Select Dates'),
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
              // POST /api/counselor/availability/block
              Navigator.pop(context);
              showSuccessSnackBar(context, 'Time blocked successfully');
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

}
