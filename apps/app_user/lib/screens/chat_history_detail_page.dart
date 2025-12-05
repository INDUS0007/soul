import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:common/api/api_client.dart';

class AppPalette {
  static const primary = Color(0xFF8B5FBF);
  static const accent = Color(0xFF4AC6B7);
  static const background = Color(0xFFFDFBFF);
  static const text = Color(0xFF1A1B41);
  static const subtext = Color(0xFF6B6B8E);
}

/// Page to display full chat history (read-only view).
class ChatHistoryDetailPage extends StatefulWidget {
  final int chatId;
  final String counsellorName;
  final DateTime chatDate;
  final int messageCount;
  final String durationDisplay;

  const ChatHistoryDetailPage({
    super.key,
    required this.chatId,
    required this.counsellorName,
    required this.chatDate,
    required this.messageCount,
    required this.durationDisplay,
  });

  @override
  State<ChatHistoryDetailPage> createState() => _ChatHistoryDetailPageState();
}

class _ChatHistoryDetailPageState extends State<ChatHistoryDetailPage> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      debugPrint('[ChatHistoryDetail] Loading messages for chat ${widget.chatId}');
      final messages = await _api.getChatMessages(widget.chatId);
      debugPrint('[ChatHistoryDetail] Loaded ${messages.length} messages');
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('[ChatHistoryDetail] Error loading messages: $e');
      debugPrint('[ChatHistoryDetail] Stack: $stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.counsellorName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              DateFormat('dd MMM yyyy, h:mm a').format(
                widget.chatDate.isUtc 
                  ? widget.chatDate.toLocal() 
                  : DateTime.utc(
                      widget.chatDate.year, widget.chatDate.month, widget.chatDate.day,
                      widget.chatDate.hour, widget.chatDate.minute, widget.chatDate.second
                    ).toLocal()
              ),
              style: const TextStyle(
                color: AppPalette.subtext,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Chat info header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppPalette.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(Icons.message, '${widget.messageCount} messages'),
                _buildInfoChip(Icons.timer, widget.durationDisplay),
                _buildInfoChip(
                  Icons.calendar_today,
                  DateFormat('dd/MM/yyyy').format(
                    widget.chatDate.isUtc 
                      ? widget.chatDate.toLocal() 
                      : DateTime.utc(
                          widget.chatDate.year, widget.chatDate.month, widget.chatDate.day,
                          widget.chatDate.hour, widget.chatDate.minute, widget.chatDate.second
                        ).toLocal()
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppPalette.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppPalette.text,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppPalette.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppPalette.subtext),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppPalette.text),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: AppPalette.subtext),
            SizedBox(height: 12),
            Text(
              'No messages in this conversation',
              style: TextStyle(color: AppPalette.subtext),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  // Parse UTC timestamp and convert to local time
  DateTime? _parseUtcToLocal(String? dateStr) {
    if (dateStr == null) return null;
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return null;
    // If parsed as UTC (has Z or +00:00), convert to local
    // Otherwise treat as UTC and convert
    return parsed.isUtc ? parsed.toLocal() : DateTime.utc(
      parsed.year, parsed.month, parsed.day,
      parsed.hour, parsed.minute, parsed.second, parsed.millisecond
    ).toLocal();
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final text = message['text'] as String? ?? '';
    final isUser = message['is_user'] as bool? ?? 
                   (message['sender_name'] as String?)?.toLowerCase() != 'counsellor';
    final timestamp = _parseUtcToLocal(message['created_at'] as String?);
    final senderName = message['sender_name'] as String? ?? 
                       (isUser ? 'You' : widget.counsellorName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppPalette.primary,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : 'C',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppPalette.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppPalette.text,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(timestamp),
                    style: const TextStyle(
                      color: AppPalette.subtext,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppPalette.accent,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

