import 'package:flutter/material.dart';
import 'package:common/api/api_client.dart' hide SessionType;
import 'package:common/widgets/widgets.dart';
import '../models/session.dart';
import 'chat_session_screen.dart';
import 'dart:async';

class QueuedChatsScreen extends StatefulWidget {
  const QueuedChatsScreen({super.key});

  @override
  State<QueuedChatsScreen> createState() => _QueuedChatsScreenState();
}

class _QueuedChatsScreenState extends State<QueuedChatsScreen> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _queuedChats = [];
  List<Map<String, dynamic>> _activeChats = [];
  List<Map<String, dynamic>> _previousChats = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadQueuedChats();
    // Auto-refresh every 30 seconds (reduced from 10 to reduce log noise)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadQueuedChats();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQueuedChats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('[QueuedChatsScreen] Fetching queued chats from API...');
      final queuedChatsData = await _api.getQueuedChats();
      print('[QueuedChatsScreen] API returned ${queuedChatsData.length} queued chats');
      
      // Also fetch all chats to get previous chats (active/completed)
      print('[QueuedChatsScreen] Fetching all chats to get previous chats...');
      final allChatsData = await _api.getChatList();
      print('[QueuedChatsScreen] API returned ${allChatsData.length} total chats');
      
      // Separate into active and previous chats
      final activeChatsData = allChatsData.where((chat) {
        final status = chat['status']?.toString().toLowerCase();
        return status == 'active';
      }).toList();
      
      final previousChatsData = allChatsData.where((chat) {
        final status = chat['status']?.toString().toLowerCase();
        return status == 'completed' || status == 'cancelled';
      }).toList();
      
      // Sort active chats by most recent first
      activeChatsData.sort((a, b) {
        final aTime = a['updated_at'] ?? a['created_at'];
        final bTime = b['updated_at'] ?? b['created_at'];
        return _compareDates(bTime, aTime);
      });
      
      // Sort previous chats by most recent first
      previousChatsData.sort((a, b) {
        final aTime = a['ended_at'] ?? a['updated_at'] ?? a['created_at'];
        final bTime = b['ended_at'] ?? b['updated_at'] ?? b['created_at'];
        return _compareDates(bTime, aTime);
      });
      
      print('[QueuedChatsScreen] Found ${activeChatsData.length} active chats and ${previousChatsData.length} previous chats');
      
      if (mounted) {
        setState(() {
          _queuedChats = queuedChatsData;
          _activeChats = activeChatsData;
          _previousChats = previousChatsData;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      print('[QueuedChatsScreen] Error loading chats: $e');
      print('[QueuedChatsScreen] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openChatSession(Map<String, dynamic> chat) async {
    final chatIdRaw = chat['id'];
    final chatId = chatIdRaw is int 
        ? chatIdRaw 
        : (chatIdRaw is String 
            ? int.tryParse(chatIdRaw) 
            : null);
    
    if (chatId == null) {
      showErrorSnackBar(context, 'Invalid chat ID');
      return;
    }

    try {
      // Get chat details
      final chatData = await _api.getChatList();
      final currentChat = chatData.firstWhere(
        (c) => (c['id'] is int ? c['id'] : int.tryParse(c['id'].toString())) == chatId,
        orElse: () => chat,
      );
      
      if (!mounted) return;

      // Create a session from the chat
      final now = DateTime.now();
      final session = Session(
        id: chatId.toString(),
        clientId: currentChat['user_username'] ?? currentChat['user']?.toString() ?? '',
        clientName: currentChat['user_name'] ?? currentChat['user_username'] ?? 'Client',
        counselorId: '', // Will be set from profile
        scheduledTime: now,
        startTime: now,
        type: SessionType.chat,
        status: SessionStatus.inProgress,
        durationMinutes: 60,
        notes: currentChat['initial_message']?.toString(),
      );

      // Navigate to chat session
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatSessionScreen(session: session),
        ),
      ).then((_) {
        // Refresh list when returning
        _loadQueuedChats();
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to open chat: $e');
    }
  }

  Future<void> _handleAcceptChat(Map<String, dynamic> chat) async {
    final chatIdRaw = chat['id'];
    final chatId = chatIdRaw is int 
        ? chatIdRaw 
        : (chatIdRaw is String 
            ? int.tryParse(chatIdRaw) 
            : null);
    
    if (chatId == null) {
      showErrorSnackBar(context, 'Invalid chat ID');
      return;
    }

    try {
      final chatData = await _api.acceptChat(chatId);
      
      if (!mounted) return;

      // Create a session from the accepted chat
      final now = DateTime.now();
      final session = Session(
        id: chatId.toString(),
        clientId: chatData['user_username'] ?? chatData['user']?.toString() ?? '',
        clientName: chatData['user_name'] ?? chatData['user_username'] ?? 'Client',
        counselorId: '', // Will be set from profile
        scheduledTime: now,
        startTime: now,
        type: SessionType.chat,
        status: SessionStatus.inProgress,
        durationMinutes: 60,
        notes: chatData['initial_message']?.toString(),
      );

      // Navigate to chat session
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatSessionScreen(session: session),
        ),
      ).then((_) {
        // Refresh list when returning
        _loadQueuedChats();
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to accept chat: $e');
    }
  }

  int _compareDates(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    final aDate = DateTime.tryParse(a.toString());
    final bDate = DateTime.tryParse(b.toString());
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }

  // Check if previous chat can be reopened (< 1 hour)
  // Uses same logic as backend: checks if ended_at is within the last hour
  bool _canReopenChat(Map<String, dynamic> chat) {
    final endedAt = chat['ended_at'];
    if (endedAt == null) return false;
    final endedDate = DateTime.tryParse(endedAt.toString());
    if (endedDate == null) return false;
    
    // Use same logic as backend: check if ended_at is >= one_hour_ago
    // This means the chat ended within the last hour (can reopen)
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    return endedDate.isAfter(oneHourAgo) || endedDate.isAtSameMomentAs(oneHourAgo);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQueuedChats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadQueuedChats,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading queued chats',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadQueuedChats,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _queuedChats.isEmpty && _activeChats.isEmpty && _previousChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No chats',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'New chat requests will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Queued Chats Section
                          if (_queuedChats.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.pending_actions,
                                  size: 20,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Queued Chats (${_queuedChats.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._queuedChats.map((chat) => _buildChatCard(chat, chatType: 'queued')),
                            const SizedBox(height: 24),
                          ],
                          
                          // Active Chats Section
                          if (_activeChats.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.chat,
                                  size: 20,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Active Chats (${_activeChats.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._activeChats.map((chat) => _buildChatCard(chat, chatType: 'active')),
                            const SizedBox(height: 24),
                          ],
                          
                          // Previous Chats Section
                          if (_previousChats.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 20,
                                  color: Colors.purple[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Previous Chats (${_previousChats.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._previousChats.map((chat) => _buildChatCard(chat, chatType: 'previous')),
                          ],
                        ],
                      ),
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat, {required String chatType}) {
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
    final updatedAt = chat['updated_at'] != null
        ? DateTime.tryParse(chat['updated_at'].toString())
        : null;
    final canReopen = chatType == 'previous' && _canReopenChat(chat);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showChatPreview(chat),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.purple.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (createdAt != null || updatedAt != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(updatedAt ?? createdAt!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: chatType == 'queued' 
                          ? Colors.orange.withOpacity(0.2)
                          : chatType == 'active'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chatType == 'queued' 
                          ? 'QUEUED'
                          : chatType == 'active'
                              ? 'ACTIVE'
                              : canReopen
                                  ? 'REOPEN'
                                  : 'EXPIRED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: chatType == 'queued' 
                            ? Colors.orange
                            : chatType == 'active'
                                ? Colors.green
                                : canReopen
                                    ? Colors.purple
                                    : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              
              // Initial message preview
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      initialMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Action buttons based on chat type
              if (chatType == 'queued')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: chatId != null 
                            ? () => _handleAcceptChat(chat)
                            : null,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                )
              else if (chatType == 'active')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: chatId != null 
                            ? () => _openChatSession(chat)
                            : null,
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('Open Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                )
              else if (chatType == 'previous')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: canReopen && chatId != null 
                            ? () => _openChatSession(chat)
                            : null,
                        icon: Icon(canReopen ? Icons.refresh : Icons.lock, size: 18),
                        label: Text(canReopen ? 'Reopen Chat (< 1 hour)' : 'Expired (> 1 hour)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: canReopen ? Colors.purple : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatPreview(Map<String, dynamic> chat) {
    final userName = chat['user_name'] ?? chat['user_username'] ?? 'Client';
    final initialMessage = chat['initial_message']?.toString() ?? 'No initial message';
    final createdAt = chat['created_at'] != null
        ? DateTime.tryParse(chat['created_at'].toString())
        : null;
    final updatedAt = chat['updated_at'] != null
        ? DateTime.tryParse(chat['updated_at'].toString())
        : null;
    final status = chat['status']?.toString().toLowerCase() ?? 'unknown';
    final chatType = status == 'queued' ? 'queued' : (status == 'active' ? 'active' : 'previous');
    final canReopen = chatType == 'previous' && _canReopenChat(chat);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(userName),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (createdAt != null || updatedAt != null) ...[
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      chatType == 'queued' 
                          ? 'Received: ${_formatTime(createdAt!)}'
                          : 'Last updated: ${_formatTime(updatedAt ?? createdAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Initial Message:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  initialMessage,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
              if (chatType == 'previous') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: canReopen ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        canReopen ? Icons.check_circle : Icons.lock,
                        size: 16,
                        color: canReopen ? Colors.green : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          canReopen 
                              ? 'This chat can be reopened (ended less than 1 hour ago)'
                              : 'This chat expired (ended more than 1 hour ago)',
                          style: TextStyle(
                            fontSize: 12,
                            color: canReopen ? Colors.green[700] : Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (chatType == 'queued')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleAcceptChat(chat);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept Chat'),
            )
          else if (chatType == 'active')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openChatSession(chat);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Chat'),
            )
          else if (chatType == 'previous' && canReopen)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openChatSession(chat);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reopen Chat'),
            ),
        ],
      ),
    );
  }
}

