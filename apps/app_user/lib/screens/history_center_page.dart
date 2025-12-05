import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:common/api/api_client.dart';
import 'chat_history_detail_page.dart';

class AppPalette {
  static const primary = Color(0xFF8B5FBF);
  static const accent = Color(0xFF4AC6B7);
  static const bg = Color(0xFFFDFBFF);
  static const cardBg = Color(0xFFFFFFFF);
  static const text = Color(0xFF1A1B41);
  static const subtext = Color(0xFF6B6B8E);
  static const soft = Color(0xFFF0EBFF);
  static const border = Color(0xFFF5F3FF);
}

class HistoryCenterPage extends StatefulWidget {
  const HistoryCenterPage({super.key});

  @override
  State<HistoryCenterPage> createState() => _HistoryCenterPageState();
}

class _HistoryCenterPageState extends State<HistoryCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ApiClient _api = ApiClient();
  
  // Chat history state
  bool _loadingChatHistory = true;
  String? _chatHistoryError;
  List<ChatHistoryItem> _chatHistory = const <ChatHistoryItem>[];
  List<ChatHistoryItem> _activeChats = const <ChatHistoryItem>[];
  
  // Sessions state (for calls)
  bool _loadingSessions = true;
  String? _sessionsError;
  List<UpcomingSessionItem> _sessions = const <UpcomingSessionItem>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChatHistory();
    _loadSessions();
  }

  Future<void> _loadChatHistory({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loadingChatHistory = true;
        _chatHistoryError = null;
      });
    } else {
      setState(() {
        _chatHistoryError = null;
      });
    }

    try {
      final response = await _api.getChatHistory();
      if (!mounted) return;
      setState(() {
        _chatHistory = response.history;
        _activeChats = response.activeChats;
        _loadingChatHistory = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _chatHistoryError = error.message;
        _loadingChatHistory = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[HistoryCenter] Error loading chat history: $error');
      debugPrint('[HistoryCenter] Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _chatHistoryError = 'Error: $error';
        _loadingChatHistory = false;
      });
    }
  }

  Future<void> _loadSessions({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loadingSessions = true;
        _sessionsError = null;
      });
    } else {
      setState(() {
        _sessionsError = null;
      });
    }

    try {
      final sessions = await _api.fetchUpcomingSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loadingSessions = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _sessionsError = error.message;
        _loadingSessions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sessionsError = 'Unable to load session history. Please try again.';
        _loadingSessions = false;
      });
    }
  }

  Future<void> _refreshChatHistory() => _loadChatHistory(showLoader: false);
  Future<void> _refreshSessions() => _loadSessions(showLoader: false);

  List<UpcomingSessionItem> get _sortedSessions {
    final list = [..._sessions];
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History Center',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        foregroundColor: AppPalette.primary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppPalette.primary,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
            Tab(icon: Icon(Icons.call_outlined), text: 'Calls'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'Payments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildChatHistory(), _buildCallHistory(), _buildPayments()],
      ),
    );
  }

  Widget _buildChatHistory() {
    if (_loadingChatHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chatHistoryError != null) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        children: [
          const Icon(Icons.history, size: 48, color: AppPalette.subtext),
          const SizedBox(height: 12),
          Text(
            _chatHistoryError!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppPalette.text),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loadChatHistory,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    // Combine active and history, with active first
    final allChats = [..._activeChats, ..._chatHistory];
    
    if (allChats.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 48, color: AppPalette.subtext),
          const SizedBox(height: 12),
          const Text(
            'Your chat history will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'After chatting with a counsellor, your conversation history will be saved here. '
            'You can view past connections and their details.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppPalette.subtext),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshChatHistory,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: allChats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final chat = allChats[index];
          final isActive = chat.status == 'active' || chat.status == 'queued' || chat.status == 'inactive';
          final counsellorName = chat.counsellorName ?? 'Counsellor';
          
          // Get last message preview
          String subtitle;
          if (chat.lastMessage != null) {
            final prefix = chat.lastMessage!.isUser ? 'You: ' : '';
            subtitle = '$prefix${chat.lastMessage!.text}';
          } else if (chat.initialMessage != null && chat.initialMessage!.isNotEmpty) {
            subtitle = chat.initialMessage!;
          } else {
            subtitle = '${chat.messageCount} messages • ${chat.durationDisplay}';
          }
          
          // Convert UTC time to local time for display
          final localTime = chat.createdAt.isUtc 
              ? chat.createdAt.toLocal() 
              : DateTime.utc(
                  chat.createdAt.year, chat.createdAt.month, chat.createdAt.day,
                  chat.createdAt.hour, chat.createdAt.minute, chat.createdAt.second
                ).toLocal();
          final dateText = DateFormat('dd/MM/yyyy').format(localTime);
          final timeText = DateFormat('h:mm a').format(localTime);

          void openChatDetail() {
            debugPrint('[HistoryCenter] Opening chat ${chat.id}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatHistoryDetailPage(
                  chatId: chat.id,
                  counsellorName: counsellorName,
                  chatDate: chat.createdAt,
                  messageCount: chat.messageCount,
                  durationDisplay: chat.durationDisplay,
                ),
              ),
            );
          }

          return Card(
            color: AppPalette.cardBg,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isActive ? AppPalette.accent : AppPalette.border,
                width: isActive ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: openChatDetail,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? AppPalette.accent : AppPalette.primary,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      counsellorName,
                      style: const TextStyle(
                        color: AppPalette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppPalette.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        chat.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppPalette.subtext),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.message, size: 12, color: AppPalette.subtext),
                      const SizedBox(width: 4),
                      Text(
                        '${chat.messageCount}',
                        style: const TextStyle(fontSize: 12, color: AppPalette.subtext),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.timer, size: 12, color: AppPalette.subtext),
                      const SizedBox(width: 4),
                      Text(
                        chat.durationDisplay,
                        style: const TextStyle(fontSize: 12, color: AppPalette.subtext),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateText,
                    style: const TextStyle(
                      color: AppPalette.subtext,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: AppPalette.subtext,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
                isThreeLine: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallHistory() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        const Icon(Icons.call, size: 48, color: AppPalette.subtext),
        const SizedBox(height: 12),
        const Text(
          'Your call history will appear here',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Once you speak with a counsellor, details such as duration and date will be listed below. '
          'Here is a sample entry for reference:',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppPalette.subtext),
        ),
        const SizedBox(height: 24),
        Card(
          color: AppPalette.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppPalette.border),
          ),
          child: const ListTile(
            leading: CircleAvatar(
              backgroundColor: AppPalette.primary,
              child: Icon(Icons.call, color: Colors.white),
            ),
            title: Text(
              'Therapist Sample',
              style: TextStyle(color: AppPalette.text),
            ),
            subtitle: Text('Duration: 20 mins'),
            trailing: Text(
              '14/11/2025',
              style: TextStyle(color: AppPalette.subtext, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayments() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        const Icon(Icons.payments, size: 48, color: AppPalette.subtext),
        const SizedBox(height: 12),
        const Text(
          'Payment records will show here',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'When you purchase sessions or recharge your wallet, a receipt entry will be listed below. '
          'Here is an illustrative example:',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppPalette.subtext),
        ),
        const SizedBox(height: 24),
        Card(
          color: AppPalette.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppPalette.border),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppPalette.soft,
              child: Icon(Icons.receipt_long, color: AppPalette.primary),
            ),
            title: const Text(
              '#TXN1204',
              style: TextStyle(color: AppPalette.text),
            ),
            subtitle: const Text('UPI • 499 INR'),
            trailing: SizedBox(
              height: 48,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '05/11/2025',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

