import 'package:flutter/material.dart';
import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';
import '../models/session.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

class ChatSessionScreen extends StatefulWidget {
  final Session session;

  const ChatSessionScreen({super.key, required this.session});

  @override
  State<ChatSessionScreen> createState() => _ChatSessionScreenState();
}

class _ChatSessionScreenState extends State<ChatSessionScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiClient _api = ApiClient();

  late Session _session;
  bool _isSessionActive = false;
  DateTime? _startTime;
  DateTime? _endTime;
  Timer? _timer;
  Timer? _messagePollTimer;
  int _elapsedSeconds = 0;
  RiskLevel _selectedRisk = RiskLevel.none;
  bool _sendingMessage = false;

  // Manual flag colors
  String _manualFlag = 'green'; // 'green', 'yellow', 'red'

  final List<ChatMessage> _messages = [];
  int? _chatId;
  String? _chatStatus; // Track chat status: active, inactive, completed, etc.
  WebSocketChannel? _webSocketChannel;
  StreamSubscription? _webSocketSubscription;
  bool _isConnectingWebSocket = false;
  bool _webSocketConnectionFailed = false;
  final _uuid = const Uuid();
  
  // Track pending messages by client_message_id for ACK handling
  final Map<String, ChatMessage> _pendingMessages = {};
  final Map<String, Timer> _messageTimeouts = {};

  void _closeWebSocket() {
    try {
      _webSocketSubscription?.cancel();
      _webSocketSubscription = null;
    } catch (e) {
      // Ignore errors during cleanup
    }
    try {
      _webSocketChannel?.sink.close();
      _webSocketChannel = null;
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
  
  void _startTimer() {
    // Cancel existing timer if any
    _timer?.cancel();
    _timer = null;
    
    // Verify session is active before starting timer
    if (!_isSessionActive) {
      print('[Counselor Timer] WARNING: Cannot start timer - session not active');
      return;
    }
    
    if (!mounted) {
      print('[Counselor Timer] WARNING: Cannot start timer - widget not mounted');
      return;
    }
    
    print('[Counselor Timer] ========================================');
    print('[Counselor Timer] Starting timer - _isSessionActive: $_isSessionActive, _elapsedSeconds: $_elapsedSeconds');
    
    // Start timer to increment every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        print('[Counselor Timer] Widget not mounted, cancelling timer');
        timer.cancel();
        _timer = null;
        return;
      }
      
      // Always check both conditions in the callback
      if (!_isSessionActive) {
        print('[Counselor Timer] Session not active, cancelling timer');
        timer.cancel();
        _timer = null;
        return;
      }
      
      // Increment elapsed seconds and update UI
      // Use setState to trigger UI rebuild
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
        // Log every 10 seconds to avoid log spam
        if (_elapsedSeconds % 10 == 0) {
          print('[Counselor Timer] Timer tick: elapsedSeconds = $_elapsedSeconds, _isSessionActive = $_isSessionActive');
        }
      }
    });
    
    print('[Counselor Timer] Timer started successfully - will increment every second');
    print('[Counselor Timer] ========================================');
  }

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _selectedRisk = _session.riskLevel;
    _notesController.text = _session.notes ?? '';
    _chatId = int.tryParse(_session.id);

    // Add initial system message
    _messages.add(
      ChatMessage(
        text:
            'Chat session scheduled for ${_formatTime(_session.scheduledTime)}',
        isClient: false,
        isSystem: true,
        timestamp: DateTime.now(),
      ),
    );

    // Load initial message if available (from accepted chat)
    // Use Future.microtask to ensure setState is called after initState completes
    Future.microtask(() async {
      await _loadInitialChatData();
    
      // Always start polling to check chat status dynamically
      // This allows WebSocket to connect when chat becomes active
      _startMessagePolling();
      
      // If session is already active, connect WebSocket immediately
    if (_session.status == SessionStatus.inProgress) {
        print('[Counselor Timer] Session already in progress - starting timer');
      _isSessionActive = true;
      // Initialize _startTime from session if available
      _startTime = _session.startTime ?? DateTime.now();
        
        // Calculate initial elapsed seconds if startTime is available
        if (_startTime != null) {
          final now = DateTime.now();
          final duration = now.difference(_startTime!);
          _elapsedSeconds = duration.inSeconds;
          print('[Counselor Timer] Calculated initial elapsed time: $_elapsedSeconds seconds (start: $_startTime, now: $now)');
        } else {
          print('[Counselor Timer] No startTime found, starting from 0');
          _elapsedSeconds = 0;
        }
        
        // Start timer to keep incrementing elapsed seconds
        _startTimer();
        
        _connectWebSocket(); // Connect WebSocket for real-time messaging
      } else if (_chatId != null) {
        // Even if session not started, check if chat is active and connect
        // This handles the case where chat is accepted but session hasn't started
        print('[Counselor WebSocket] Session not active, but checking if chat $_chatId is active...');
        // _fetchChatMessages() will check status and auto-start session if chat is active
        // This is already called in _loadInitialChatData() above
    }
    });
  }

  Future<void> _loadInitialChatData() async {
    // Small delay to ensure widget is fully built
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    // ALWAYS load messages from database first (this ensures persistence after refresh)
    if (_chatId != null) {
      print('[Counselor Chat] ========================================');
      print('[Counselor Chat] Loading messages from database for chat $_chatId');
      print('[Counselor Chat] Session ID: ${_session.id}');
      print('[Counselor Chat] Session Status: ${_session.status}');
      print('[Counselor Chat] ========================================');
      await _fetchChatMessages();
    } else {
      print('[Counselor Chat] WARNING: _chatId is null, cannot load messages');
      print('[Counselor Chat] Session ID: ${_session.id}');
    }
    
    // Load initial message from session notes (temporarily stored there)
    // Only add if it's not already in the loaded messages
    if (_session.notes != null && _session.notes!.trim().isNotEmpty) {
      // Check if notes contain the initial message (from accepted chat)
      final initialMessage = _session.notes!.trim();
      // Only add if it's not a system message and not empty
      if (initialMessage.isNotEmpty && 
          !initialMessage.startsWith('Chat session') &&
          !initialMessage.startsWith('Session started')) {
        // Check if this message is already in the list (from database)
        final messageExists = _messages.any((msg) => 
          msg.text == initialMessage && msg.isClient);
        
        if (!messageExists && mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: initialMessage,
                isClient: true,
                isSystem: false,
                timestamp: _session.scheduledTime,
              ),
            );
            // Sort messages by timestamp after adding
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
          _scrollToBottom();
        }
      }
    }
  }

  Future<void> _fetchChatMessages() async {
    if (_chatId == null) {
      print('[Counselor Chat] Cannot fetch messages: chatId is null');
      return;
    }
    
    try {
      print('[Counselor Chat] Fetching messages from API for chat $_chatId');
      
      // Get chat status from chat list
      try {
        final chatList = await _api.getChatList();
        final currentChat = chatList.firstWhere(
          (chat) => chat['id'] == _chatId,
          orElse: () => <String, dynamic>{},
        );
        if (currentChat.isNotEmpty && mounted) {
          final newChatStatus = currentChat['status']?.toString();
          setState(() {
            _chatStatus = newChatStatus;
          });
          
          // Auto-start session and timer if chat is active or inactive (but session not started yet)
          if ((newChatStatus == 'active' || newChatStatus == 'inactive') && 
              !_isSessionActive && 
              _session.status != SessionStatus.inProgress) {
            print('[Counselor Timer] Chat is active/inactive but session not started - auto-starting session and timer');
            _autoStartSession();
          }
        }
      } catch (e) {
        print('[Counselor Chat] Error fetching chat status: $e');
      }
      
      final messages = await _api.getChatMessages(_chatId!);
      print('[Counselor Chat] Received ${messages.length} messages from API');
      
      if (mounted) {
        // Keep system messages
        final systemMessages = _messages.where((m) => m.isSystem).toList();
        
        // FIXED: Deduplicate within the API response itself using message_id
        // This prevents filtering out valid messages that happen to have the same text
        final seenMessageIds = <int>{};
        final seenClientMessageIds = <String>{};
        final deduplicatedMessages = <Map<String, dynamic>>[];
        
        for (var msg in messages) {
          final msgId = msg['id'] != null ? int.tryParse(msg['id'].toString()) : null;
          final clientMsgId = msg['client_message_id']?.toString();
          
          // Use message_id for deduplication (most reliable)
          if (msgId != null) {
            if (seenMessageIds.contains(msgId)) {
              print('[Counselor Chat] Skipping duplicate by message_id: $msgId');
              continue;
            }
            seenMessageIds.add(msgId);
          } else if (clientMsgId != null) {
            // Fallback to client_message_id
            if (seenClientMessageIds.contains(clientMsgId)) {
              print('[Counselor Chat] Skipping duplicate by client_message_id: $clientMsgId');
              continue;
            }
            seenClientMessageIds.add(clientMsgId);
          }
          
          deduplicatedMessages.add(msg);
        }
        
        print('[Counselor Chat] Deduplicated: ${messages.length} -> ${deduplicatedMessages.length} messages');
        
        // Now build ChatMessage objects from deduplicated API response
        final newMessages = <ChatMessage>[];
        for (var msg in deduplicatedMessages) {
          final msgText = msg['text']?.toString() ?? '';
          final isClient = msg['is_user'] == true;
          final timestampStr = msg['created_at']?.toString() ?? '';
          final timestamp = timestampStr.isNotEmpty 
              ? DateTime.tryParse(timestampStr) ?? DateTime.now()
              : DateTime.now();
          
          newMessages.add(ChatMessage(
            text: msgText,
            isClient: isClient,
            isSystem: false,
            timestamp: timestamp,
          ));
        }
        
        print('[Counselor Chat] Adding ${newMessages.length} messages from API');
        
        // Replace all non-system messages with fresh data from API
        // This ensures we show all messages from the database
        setState(() {
          _messages.clear();
          _messages.addAll(systemMessages);
          _messages.addAll(newMessages);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
        
        print('[Counselor Chat] Total messages after load: ${_messages.length}');
        _scrollToBottom();
      }
    } catch (e, stackTrace) {
      print('[Counselor Chat] Error fetching messages: $e');
      print('[Counselor Chat] Stack trace: $stackTrace');
      // Show error to user if messages fail to load
      if (mounted) {
        showErrorSnackBar(context, 'Failed to load chat history: $e');
      }
    }
  }

  void _startMessagePolling() {
    // Cancel existing polling
    _messagePollTimer?.cancel();
    _messagePollTimer = null;
    
    // IMPORTANT: If WebSocket is already connected, DO NOT start polling
    // WebSocket handles all messages in real-time, polling is only a fallback
    if (_webSocketChannel != null && !_webSocketConnectionFailed) {
      print('[Counselor Chat] WebSocket is connected, skipping polling setup');
      return;
    }
    
    // Poll for new messages every 15 seconds (increased from 10 to reduce server load)
    // Only used as fallback when WebSocket is not available
    _messagePollTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted || _chatId == null) {
        timer.cancel();
        _messagePollTimer = null;
        return;
      }
      
      // If WebSocket connected while polling was running, stop polling
      if (_webSocketChannel != null && !_webSocketConnectionFailed) {
        print('[Counselor Chat] WebSocket connected, stopping polling');
        timer.cancel();
        _messagePollTimer = null;
        return;
      }
      
      // Only poll if WebSocket is NOT connected
      // This allows WebSocket to connect when chat becomes active
      if (_webSocketChannel == null || _webSocketConnectionFailed) {
        _checkForNewMessages(); // This checks chat status and connects WebSocket if needed
      }
    });
  }
  
  void _stopMessagePolling() {
    // Stop polling when WebSocket is connected
    _messagePollTimer?.cancel();
    _messagePollTimer = null;
    print('[Counselor Chat] Message polling stopped');
  }

  void _connectWebSocket() {
    // Prevent multiple connection attempts
    if (_isConnectingWebSocket || _webSocketConnectionFailed) return;
    
    if (_chatId == null) {
      print('[Counselor WebSocket] Cannot connect: _chatId is null');
      return;
    }
    
    // Connect if session is active OR if we have a chatId (chat might be active or inactive)
    // We'll check chat status dynamically
    // Allow connection for active or inactive chats
    if (!_isSessionActive) {
      print('[Counselor WebSocket] Session not active, but will try to connect for active/inactive chat');
      // Don't return - allow connection attempt for active/inactive chats
    }

    _isConnectingWebSocket = true;
    print('[Counselor WebSocket] Attempting to connect to chat $_chatId (session_active: $_isSessionActive)');

    // Close existing connection if any (safely)
    _closeWebSocket();

    // Connect to WebSocket (async, so we need to handle it properly)
    _api.connectChatWebSocket(_chatId!).then((channel) {
        if (!mounted) {
          channel.sink.close();
          _isConnectingWebSocket = false;
          return;
        }
        
        _webSocketChannel = channel;
        _isConnectingWebSocket = false;
        _webSocketConnectionFailed = false; // Reset failure flag on success

        print('[Counselor WebSocket] Connected to chat $_chatId');
        
        // IMPORTANT: Stop polling when WebSocket connects successfully
        // WebSocket handles all messages in real-time, no need for polling
        _stopMessagePolling();

        // Listen for incoming messages
        _webSocketSubscription = channel.stream.listen(
          (data) {
          try {
            print('[Counselor WebSocket] Received raw data: $data');
            final messageData = jsonDecode(data);
            print('[Counselor WebSocket] Parsed JSON: $messageData');
            
            // Handle ACK messages first
            if (messageData['type'] == 'ack') {
              final clientMessageId = messageData['client_message_id']?.toString();
              
              if (clientMessageId != null && _pendingMessages.containsKey(clientMessageId)) {
                print('[Counselor WebSocket] Received ACK for client_message_id: $clientMessageId');
                final pendingMessage = _pendingMessages[clientMessageId];
                
                // Cancel timeout
                _messageTimeouts[clientMessageId]?.cancel();
                _messageTimeouts.remove(clientMessageId);
                
                // Update message status to sent
                if (mounted && pendingMessage != null) {
                  setState(() {
                    pendingMessage.status = MessageStatus.sent;
                    _sendingMessage = false; // Reset sending flag
                  });
                  _pendingMessages.remove(clientMessageId);
                  print('[Counselor WebSocket] Message marked as sent, removed from pending');
                }
              }
              return;
            }
            
            // Handle chat status updates (separate from chat messages)
            if (messageData['type'] == 'chat_status_update') {
              print('[Counselor WebSocket] Received chat status update');
              final newStatus = messageData['new_status']?.toString();
              if (newStatus != null && mounted) {
                setState(() {
                  _chatStatus = newStatus;
                });
                
                // Show notification if chat became inactive
                if (newStatus == 'inactive') {
                  showErrorSnackBar(context, 'Chat is inactive - user hasn\'t sent a message in 5+ minutes');
                }
              }
              return;
            }
            
            if (messageData['error'] != null) {
              final errorMsg = messageData['error'].toString();
              print('[Counselor WebSocket] Error: $errorMsg');
              
              // Mark pending messages as failed if error
              if (mounted) {
                _pendingMessages.values.forEach((msg) {
                  if (msg.status == MessageStatus.sending) {
                    msg.status = MessageStatus.failed;
                  }
                });
                _sendingMessage = false;
                
                showErrorSnackBar(context, errorMsg);
              }
              return;
            }

            // STRICT TYPE CHECK: Only process chat messages with type "message" or "chat_message"
            // Backend sends: type "message" via chat_message handler, type "chat_message" via group broadcast
            final messageType = messageData['type']?.toString() ?? '';
            
            // CRITICAL: Explicitly check for non-chat types and skip them
            if (messageType == 'ack') {
              print('[Counselor WebSocket] Ignoring ACK message (already handled above)');
              return;
            }
            
            if (messageType == 'chat_status_update') {
              print('[Counselor WebSocket] Ignoring chat_status_update message (already handled above)');
              return;
            }
            
            // Only process messages with type "message" or "chat_message"
            // Also allow messages without type for backward compatibility
            if (messageType.isNotEmpty && messageType != 'message' && messageType != 'chat_message') {
              print('[Counselor WebSocket] Ignoring unknown message type: "$messageType" (expected: message, chat_message, or empty)');
              print('[Counselor WebSocket] Full message data: $messageData');
              return;
            }
            
            print('[Counselor WebSocket] Processing message with type: "$messageType" (valid chat message type)');
            
            final messageText = messageData['message']?.toString() ?? '';
            
            // Skip if message is empty
            if (messageText.isEmpty) {
              print('[Counselor WebSocket] Empty message received, skipping');
              return;
            }

            // Handle regular chat messages
            final isClient = messageData['is_user'] == true; // User's message
            final timestampStr = messageData['timestamp']?.toString() ?? '';
            final timestamp = timestampStr.isNotEmpty
                ? DateTime.tryParse(timestampStr) ?? DateTime.now()
                : DateTime.now();
            final receivedClientMessageId = messageData['client_message_id']?.toString();
            final messageId = messageData['message_id']?.toString();

            print('[Counselor WebSocket] Parsed - text: "$messageText", isClient: $isClient, timestamp: $timestamp, messageId: $messageId, client_msg_id: $receivedClientMessageId');

            if (messageText.isNotEmpty && mounted) {
              // Check if this is a duplicate of a pending message we sent (only skip if it's OUR message)
              // IMPORTANT: Don't skip messages from the user/client even if client_message_id matches
              if (receivedClientMessageId != null && 
                  _pendingMessages.containsKey(receivedClientMessageId) &&
                  !isClient) {  // Only skip if it's our own message (not from client)
                print('[Counselor WebSocket] Received broadcast of our own message, marking as sent');
                final pendingMessage = _pendingMessages[receivedClientMessageId];
                if (pendingMessage != null) {
                  setState(() {
                    pendingMessage.status = MessageStatus.sent;
                    _sendingMessage = false;
                  });
                  _messageTimeouts[receivedClientMessageId]?.cancel();
                  _messageTimeouts.remove(receivedClientMessageId);
                  _pendingMessages.remove(receivedClientMessageId);
                }
                return; // Don't add duplicate of our own message
              }
              
              // IMPROVED DEDUPLICATION: Less aggressive, prioritize message display
              // Only filter out exact duplicates (same text + same sender + very close timestamp)
              bool exists = false;
              
              // Check for duplicates - use stricter time window (2 seconds) to allow same text from different times
              exists = _messages.any((m) {
                if (!m.isSystem && m.text == messageText && m.isClient == isClient) {
                  final timeDiff = (m.timestamp.difference(timestamp).abs().inSeconds);
                  // Only consider it duplicate if within 2 seconds (very close timestamps = same message)
                  // This allows same text at different times (e.g., client says "hello" twice)
                  if (timeDiff < 2) {
                    print('[Counselor WebSocket] Duplicate detected: same text "$messageText" from same sender within ${timeDiff}s');
                    return true;
                  }
                }
                return false;
              });
              
              print('[Counselor WebSocket] Message exists: $exists | Current messages: ${_messages.length} | messageId: $messageId');
              
              if (!exists) {
                print('[Counselor WebSocket] ✓ Adding NEW message: "$messageText" | isClient: $isClient | messageId: $messageId | timestamp: $timestamp');
                print('[Counselor WebSocket] Total before: ${_messages.length}');
                setState(() {
                  _messages.add(ChatMessage(
                    text: messageText,
                    isClient: isClient,
                    isSystem: false,
                    timestamp: timestamp,
                    status: MessageStatus.sent,
                  ));
                });
                print('[Counselor WebSocket] Added message. Total after: ${_messages.length}');
                _scrollToBottom();
              } else {
                print('[Counselor WebSocket] ✗ DUPLICATE - Skipping: "$messageText" | isClient: $isClient | messageId: $messageId');
              }
            } else {
              print('[Counselor WebSocket] Message empty or widget not mounted');
            }
          } catch (e) {
            print('[Counselor WebSocket] Error parsing message: $e');
            print('[Counselor WebSocket] Raw data: $data');
          }
        },
        onError: (error) {
          // WebSocket error - silently fallback to polling
          // Don't log errors as they're expected if WebSocket isn't available
          if (mounted) {
            _isConnectingWebSocket = false;
            _webSocketConnectionFailed = true;
            _startMessagePolling();
          }
        },
        onDone: () {
          // WebSocket closed - only reconnect if session is still active and chat is active or inactive
      if (mounted && _isSessionActive && _chatId != null && (_chatStatus == 'active' || _chatStatus == 'inactive')) {
            _isConnectingWebSocket = false;
            // Don't auto-reconnect if connection failed before
            if (!_webSocketConnectionFailed) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted && _isSessionActive && _chatId != null && (_chatStatus == 'active' || _chatStatus == 'inactive')) {
                  _connectWebSocket();
                }
              });
      } else {
              // Use polling as fallback
              _startMessagePolling();
            }
          }
        },
          cancelOnError: false,
        );
      }).catchError((error) {
        // If WebSocket fails, silently fallback to polling
        // Don't log errors as they're expected if WebSocket isn't available
        if (mounted) {
          _isConnectingWebSocket = false;
          _webSocketConnectionFailed = true;
          _startMessagePolling();
      }
      }, test: (error) {
        // Catch all errors silently
        return true;
    });
  }

  Future<void> _checkForNewMessages() async {
    if (_chatId == null) return;
    
    // IMPORTANT: If WebSocket is connected, do NOT poll for messages
    // WebSocket handles all messages in real-time
    if (_webSocketChannel != null && !_webSocketConnectionFailed) {
      print('[Counselor Chat] WebSocket connected, skipping message polling');
      return;
    }
    
    try {
      // Check chat status by getting chat list (includes status)
      // This helps us track when chat becomes active and auto-start session/timer
      try {
        final chatList = await _api.getChatList();
        final currentChat = chatList.firstWhere(
          (chat) => chat['id'] == _chatId,
          orElse: () => <String, dynamic>{},
        );
        
        if (currentChat.isNotEmpty) {
          final currentStatus = currentChat['status']?.toString() ?? '';
          
          // Update chat status if it changed
          if (_chatStatus != currentStatus && mounted) {
            print('[Counselor Chat] Chat status changed: $_chatStatus -> $currentStatus');
            setState(() {
              _chatStatus = currentStatus;
            });
          }
          
          // Auto-start session and timer if chat is active or inactive (but session not started yet)
          if ((currentStatus == 'active' || currentStatus == 'inactive') && 
              !_isSessionActive && 
              _session.status != SessionStatus.inProgress) {
            print('[Counselor Timer] Chat is active/inactive but session not started - auto-starting session and timer');
            if (mounted) {
              _autoStartSession();
            }
          }
          
          // Try to connect WebSocket if chat is active or inactive
        if (_webSocketChannel == null && !_webSocketConnectionFailed && _chatId != null) {
            if (currentStatus == 'active' || currentStatus == 'inactive') {
              print('[Counselor Chat] Attempting WebSocket connection for chat $_chatId (status: $currentStatus)');
          _connectWebSocket();
          // Wait a bit to see if connection succeeds
          await Future.delayed(const Duration(milliseconds: 500));
          
          // If WebSocket connected, stop here
          if (_webSocketChannel != null && !_webSocketConnectionFailed) {
            print('[Counselor Chat] WebSocket connected successfully, stopping polling');
            _stopMessagePolling();
            return;
              }
            }
          }
        }
    } catch (e) {
        print('[Counselor Chat] Error checking chat status: $e');
        // Continue to fetch messages even if status check fails
      }
      
      // Only fetch messages via polling if WebSocket is NOT connected
      // This is the fallback mechanism
      if (_webSocketChannel == null || _webSocketConnectionFailed) {
        print('[Counselor Chat] Fetching messages via polling (WebSocket not available)');
        final messages = await _api.getChatMessages(_chatId!);
        if (mounted) {
          // Improved deduplication: use text + isClient (ignore timestamp differences)
          // This prevents duplicates from different sources with slightly different timestamps
          final existingMessages = {
            for (var msg in _messages) 
              if (!msg.isSystem) '${msg.text}_${msg.isClient}'
          };
          
          final newMessages = <ChatMessage>[];
          for (var msg in messages) {
            final msgText = msg['text']?.toString() ?? '';
            final isClient = msg['is_user'] == true;
            final timestamp = DateTime.tryParse(msg['created_at']?.toString() ?? '') ?? DateTime.now();
            final key = '${msgText}_${isClient}';
            
            if (!existingMessages.contains(key)) {
              newMessages.add(ChatMessage(
                text: msgText,
                isClient: isClient,
                isSystem: false,
                timestamp: timestamp,
              ));
            }
          }
          
          if (newMessages.isNotEmpty) {
            setState(() {
              _messages.addAll(newMessages);
              // Sort messages by timestamp
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      print('[Counselor Chat] Error in _checkForNewMessages: $e');
      // Silently fail - polling will continue if WebSocket not connected
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _messagePollTimer?.cancel();
    _messagePollTimer = null;
    
    // Cancel all message timeouts
    _messageTimeouts.values.forEach((timer) => timer.cancel());
    _messageTimeouts.clear();
    _pendingMessages.clear();
    
    _closeWebSocket();
    _messageController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _autoStartSession() {
    // Auto-start session when chat is active but session hasn't started
    if (!_isSessionActive && _chatId != null) {
      print('[Counselor Timer] ========================================');
      print('[Counselor Timer] Auto-starting session for active chat');
      print('[Counselor Timer] chatId: $_chatId, chatStatus: $_chatStatus');
      
      if (!mounted) {
        print('[Counselor Timer] Widget not mounted, cannot auto-start');
        return;
      }
      
      // Update session object first
      _session = Session(
        id: _session.id,
        clientId: _session.clientId,
        clientName: _session.clientName,
        clientPhoto: _session.clientPhoto,
        counselorId: _session.counselorId,
        scheduledTime: _session.scheduledTime,
        startTime: DateTime.now(),
        endTime: null,
        type: _session.type,
        status: SessionStatus.inProgress,
        notes: _session.notes,
        riskLevel: _session.riskLevel,
        isEscalated: _session.isEscalated,
        durationMinutes: _session.durationMinutes,
      );
      
      // Update state and start timer
      setState(() {
        _isSessionActive = true;
        _startTime = _session.startTime ?? DateTime.now();
        _elapsedSeconds = 0; // Start from 0
        print('[Counselor Timer] Set _isSessionActive=true, _startTime=$_startTime, _elapsedSeconds=$_elapsedSeconds');
      });
      
      // Start timer AFTER setState completes
      // Use Future.microtask to ensure setState has finished
      Future.microtask(() {
        if (mounted && _isSessionActive) {
          print('[Counselor Timer] Calling _startTimer() after setState...');
          _startTimer();
          print('[Counselor Timer] ========================================');
        } else {
          print('[Counselor Timer] Cannot start timer - mounted=$mounted, _isSessionActive=$_isSessionActive');
        }
      });
    } else {
      print('[Counselor Timer] Cannot auto-start: _isSessionActive=$_isSessionActive, _chatId=$_chatId');
    }
  }

  Future<void> _startSession() async {
    try {
      // Call API to start session if session ID is numeric
      final sessionId = int.tryParse(_session.id);
      if (sessionId != null) {
        try {
          await _api.startSession(sessionId);
        } catch (e) {
          // Session might already be started or endpoint might not exist
          // Continue anyway
        }
      }

      if (!mounted) return;

      setState(() {
        _isSessionActive = true;
        _startTime = DateTime.now();
        _elapsedSeconds = 0; // Reset elapsed seconds when starting new session
        _session = Session(
          id: _session.id,
          clientId: _session.clientId,
          clientName: _session.clientName,
          clientPhoto: _session.clientPhoto,
          counselorId: _session.counselorId,
          scheduledTime: _session.scheduledTime,
          startTime: _startTime,
          endTime: null,
          type: _session.type,
          status: SessionStatus.inProgress,
          notes: _session.notes,
          riskLevel: _session.riskLevel,
          isEscalated: _session.isEscalated,
          durationMinutes: _session.durationMinutes,
        );
      });

      // Start timer using helper method
      _startTimer();

      // Connect WebSocket for real-time messaging when session starts
      if (_chatId != null) {
        _connectWebSocket();
        _startMessagePolling(); // Keep polling as fallback
      }

      // Add system message
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Session started at ${_formatTime(_startTime!)}',
            isClient: false,
            isSystem: true,
            timestamp: _startTime!,
          ),
        );
      });
      _scrollToBottom();

      // Send welcome message from counselor via WebSocket or API
      if (_chatId != null) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (mounted && _chatId != null) {
            try {
              final welcomeMsg = "Hello! I'm here to support you. How can I help you today?";
              
              // Try WebSocket first
              if (_webSocketChannel != null) {
                _webSocketChannel!.sink.add(jsonEncode({
                  'message': welcomeMsg,
                  'client_message_id': _uuid.v4(), // Include for deduplication
                }));
              } else {
                // Fallback to API
                await _api.sendChatMessage(_chatId!, welcomeMsg);
              }
              // Message will appear via WebSocket stream or polling
            } catch (e) {
              // If sending fails, add locally as fallback
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: "Hello! I'm here to support you. How can I help you today?",
                isClient: false,
                isSystem: false,
                timestamp: DateTime.now(),
              ),
            );
          });
          _scrollToBottom();
              }
            }
        }
      });
      }

      // Start polling for new messages
      _startMessagePolling();

      if (mounted) {
        showSuccessSnackBar(context, 'Chat session started');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to start session: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _sendingMessage || _chatId == null) return;

    final messageText = _messageController.text.trim();
    final clientMessageId = _uuid.v4(); // Generate unique ID for deduplication
    _messageController.clear();

    // Create optimistic message with sending status
    final optimisticMessage = ChatMessage(
          text: messageText,
          isClient: false,
          isSystem: false,
          timestamp: DateTime.now(),
      clientMessageId: clientMessageId,
      status: MessageStatus.sending, // Show spinner
      );

    setState(() {
      _sendingMessage = true;
      _messages.add(optimisticMessage);
      _pendingMessages[clientMessageId] = optimisticMessage;
    });
    _scrollToBottom();

    // Set timeout: if no ACK after 30 seconds, mark as failed
    _messageTimeouts[clientMessageId] = Timer(const Duration(seconds: 30), () {
      if (mounted && _pendingMessages.containsKey(clientMessageId)) {
        print('[Counselor Chat] Message timeout: $clientMessageId');
        setState(() {
          final msg = _pendingMessages[clientMessageId];
          if (msg != null) {
            msg.status = MessageStatus.failed;
          }
          _sendingMessage = false;
          _pendingMessages.remove(clientMessageId);
        });
        _messageTimeouts.remove(clientMessageId);
      }
    });

    try {
      // Try WebSocket first (real-time)
      if (_webSocketChannel != null && !_webSocketConnectionFailed) {
        try {
          print('[Counselor Chat] Sending via WebSocket with client_message_id: $clientMessageId');
          _webSocketChannel!.sink.add(jsonEncode({
            'message': messageText,
            'client_message_id': clientMessageId, // Include for server-side deduplication
          }));
          // Don't reset _sendingMessage here - wait for ACK or broadcast
          // The ACK handler or broadcast handler will update status
          return;
        } catch (e) {
          // WebSocket failed, fallback to API
          print('[Counselor Chat] WebSocket send failed: $e');
          _webSocketConnectionFailed = true;
          _closeWebSocket();
          _startMessagePolling();
        }
      }
      
      // Fallback to API if WebSocket not connected
      print('[Counselor Chat] WebSocket not available, using API with client_message_id: $clientMessageId');
      await _api.sendChatMessage(_chatId!, messageText);
      
      // For API fallback, mark as sent immediately (API call succeeded)
      if (mounted) {
        setState(() {
          optimisticMessage.status = MessageStatus.sent;
          _sendingMessage = false;
          _pendingMessages.remove(clientMessageId);
          _messageTimeouts[clientMessageId]?.cancel();
          _messageTimeouts.remove(clientMessageId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          optimisticMessage.status = MessageStatus.failed;
          _sendingMessage = false;
          _pendingMessages.remove(clientMessageId);
          _messageTimeouts[clientMessageId]?.cancel();
          _messageTimeouts.remove(clientMessageId);
        });
        showErrorSnackBar(context, 'Failed to send message: $e');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      if (_scrollController.hasClients) {
        try {
          final position = _scrollController.position;
          if (position.hasContentDimensions && position.maxScrollExtent.isFinite) {
            _scrollController.jumpTo(position.maxScrollExtent);
          }
        } catch (e) {
          // Ignore scroll errors
        }
      }
    });
  }

  void _endSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Chat Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to end this chat session?'),
            const SizedBox(height: 16),
            Text(
              'Started: ${_formatTime(_startTime!)}',
              style: const TextStyle(fontSize: 14),
            ),
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
    _timer?.cancel();
    
    print('[Counselor Session] ========================================');
    print('[Counselor Session] _completeSession called');
    print('[Counselor Session] _session.id = "${_session.id}"');
    print('[Counselor Session] _session.id type = ${_session.id.runtimeType}');
    print('[Counselor Session] _chatId = $_chatId');
    print('[Counselor Session] _isSessionActive = $_isSessionActive');
    print('[Counselor Session] ========================================');
    
    // Try to parse session.id as int, fallback to chatId
    int? idToUse;
    if (_session.id.isNotEmpty) {
      final parsedId = int.tryParse(_session.id);
      if (parsedId != null) {
        idToUse = parsedId;
        print('[Counselor Session] Using parsed session.id: $idToUse');
      } else {
        print('[Counselor Session] Could not parse session.id "${_session.id}" as int');
      }
    }
    
    // Fallback to chatId if session.id couldn't be parsed
    if (idToUse == null && _chatId != null) {
      idToUse = _chatId;
      print('[Counselor Session] Using _chatId as fallback: $idToUse');
    }
    
    // Call API if we have an ID and session is active
    if (idToUse != null) {
      try {
        print('[Counselor Session] Calling endSession API with id: $idToUse');
        final response = await _api.endSession(idToUse);
        print('[Counselor Session] ✅ endSession API call successful: $response');
        
        if (mounted) {
          showSuccessSnackBar(context, 'Session ended successfully');
        }
      } catch (e) {
        print('[Counselor Session] ❌ endSession API call failed: $e');
        // Log error but continue with UI update
        if (mounted) {
          showErrorSnackBar(context, 'Note: Session end API call failed: $e');
        }
      }
    } else {
      print('[Counselor Session] ⚠️ Cannot call endSession: no valid ID found');
      print('[Counselor Session] session.id="${_session.id}", chatId=$_chatId');
      if (mounted) {
        showErrorSnackBar(context, 'Warning: No session ID available to end session');
      }
    }

    if (!mounted) return;

    setState(() {
      _endTime = DateTime.now();
      _isSessionActive = false;
      _session = Session(
        id: _session.id,
        clientId: _session.clientId,
        clientName: _session.clientName,
        clientPhoto: _session.clientPhoto,
        counselorId: _session.counselorId,
        scheduledTime: _session.scheduledTime,
        startTime: _startTime,
        endTime: _endTime,
        type: _session.type,
        status: SessionStatus.completed,
        notes: _notesController.text,
        riskLevel: _selectedRisk,
        isEscalated: _session.isEscalated,
        durationMinutes: _elapsedSeconds ~/ 60,
      );
    });

    // Add system message
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Session ended at ${_formatTime(_endTime!)}',
          isClient: false,
          isSystem: true,
          timestamp: _endTime!,
        ),
      );
    });

    _showSessionSummary();
  }

  void _showSessionSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Completed'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('Client', _session.clientName),
              _buildSummaryRow('Type', 'Chat Session'),
              _buildSummaryRow('Started', _formatTime(_startTime!)),
              _buildSummaryRow('Ended', _formatTime(_endTime!)),
              _buildSummaryRow('Duration', _formatDuration(_elapsedSeconds)),
              _buildSummaryRow('Messages', '${_messages.length}'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Risk Assessment
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showRiskSelectionDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getRiskColor(_selectedRisk).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getRiskColor(_selectedRisk).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          color: _getRiskColor(_selectedRisk),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Risk Assessment',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to change',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getRiskColor(_selectedRisk),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedRisk.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Manual Flag Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getManualFlagColor(_manualFlag).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getManualFlagColor(_manualFlag).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: _getManualFlagColor(_manualFlag),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manual Flag',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set by counselor',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getManualFlagColor(_manualFlag),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _manualFlag.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close summary
                    _showManualFlagDialog();
                  },
                  icon: const Icon(Icons.flag),
                  label: const Text('Set/Update Manual Flag'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Session saved successfully',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to dashboard
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_session.clientName),
            // Always show timer if session is active (even if still at 0)
            if (_isSessionActive)
              Text(
                _formatDuration(_elapsedSeconds),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              )
            // Also show timer placeholder if chat is active but session not started yet
            else if (_chatStatus == 'active' || _chatStatus == 'inactive')
              Text(
                '00:00:00',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          if (_isSessionActive)
            IconButton(
              icon: const Icon(Icons.note_add),
              onPressed: _showNotesDialog,
              tooltip: 'Add Private Notes',
            ),
        ],
      ),
      body: Column(
        children: [
          // Session Status Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: _isSessionActive
                ? Colors.green.shade50
                : Colors.grey.shade100,
            child: Row(
              children: [
                Icon(
                  _isSessionActive ? (_chatStatus == 'inactive' ? Icons.pause_circle : Icons.circle) : Icons.circle_outlined,
                  color: _isSessionActive ? (_chatStatus == 'inactive' ? Colors.orange : Colors.green) : Colors.grey,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  _isSessionActive
                      ? (_startTime != null
                          ? (_chatStatus == 'inactive'
                              ? 'Session Active - Chat Inactive (User inactive 5+ min) - Started at ${_formatTime(_startTime!)}'
                              : 'Session Active - Started at ${_formatTime(_startTime!)}')
                          : (_chatStatus == 'inactive'
                              ? 'Session Active - Chat Inactive (User inactive 5+ min)'
                              : 'Session Active'))
                      : 'Session Not Started',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isSessionActive
                        ? (_chatStatus == 'inactive' ? Colors.orange.shade900 : Colors.green.shade900)
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Risk Level Indicator (Real-time during session)
          if (_isSessionActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _getRiskColor(_selectedRisk).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: _getRiskColor(_selectedRisk),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Risk Level:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getRiskColor(_selectedRisk),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _selectedRisk.name.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Chat Messages
          Expanded(
            child: _messages.isEmpty
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
                          'Start the session to begin chatting',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (!_isSessionActive)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startSession,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Chat Session'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  else ...[
                    // Show inactive status indicator
                    if (_chatStatus == 'inactive')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pause_circle, size: 16, color: Colors.orange.shade700),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Chat Inactive - User inactive 5+ min',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_chatStatus == 'inactive') const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sendingMessage ? null : _sendMessage,
                      icon: _sendingMessage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            )
                          : const Icon(Icons.send),
                      color: Theme.of(context).primaryColor,
                      iconSize: 28,
                    ),
                    IconButton(
                      onPressed: _endSession,
                      icon: const Icon(Icons.call_end),
                      color: Colors.red,
                      iconSize: 28,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      );
    }

    // Client messages on left, Counselor messages on right
    final isClient = message.isClient;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isClient ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isClient)
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          if (isClient) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isClient
                    ? Colors.grey.shade200
                    : Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isClient ? 20 : 0),
                  bottomRight: Radius.circular(isClient ? 0 : 20),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isClient
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isClient ? Colors.grey[800] : Colors.white,
                      height: 1.4,
                    ),
                      ),
                      // Show spinner for sending messages (only for counselor messages)
                      if (!isClient && message.status == MessageStatus.sending) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white70,
                            ),
                          ),
                        ),
                      ],
                      // Show error icon for failed messages
                      if (!isClient && message.status == MessageStatus.failed) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red.shade300,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isClient
                          ? Colors.grey.shade600
                          : Colors.white70,
                    ),
                      ),
                      // Show status indicator for counselor messages
                      if (!isClient && message.status == MessageStatus.failed) ...[
                        const SizedBox(width: 4),
                        Text(
                          'Failed',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.red.shade300,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isClient) const SizedBox(width: 8),
          if (!isClient)
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.sentiment_satisfied_alt, color: Colors.white),
            ),
        ],
      ),
    );
  }

  void _showNotesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Private Notes'),
        content: TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            hintText: 'Add confidential session notes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Notes saved')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showManualFlagDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Manual Flag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select flag color:'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFlagOption('green', Colors.green, 'Green'),
                _buildFlagOption('yellow', Colors.yellow.shade700, 'Yellow'),
                _buildFlagOption('red', Colors.red, 'Red'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRiskSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Risk Level'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRiskOption(RiskLevel.none, 'No Concern'),
              _buildRiskOption(RiskLevel.low, 'Low Risk'),
              _buildRiskOption(RiskLevel.medium, 'Medium Risk'),
              _buildRiskOption(RiskLevel.high, 'High Risk'),
              _buildRiskOption(
                RiskLevel.critical,
                'Critical - Immediate Attention',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskOption(RiskLevel level, String label) {
    final isSelected = _selectedRisk == level;
    final color = _getRiskColor(level);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRisk = level;
        });
        Navigator.pop(context);
        showSuccessSnackBar(context, 'Risk level set to: $label');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagOption(String flag, Color color, String label) {
    final isSelected = _manualFlag == flag;
    return GestureDetector(
      onTap: () {
        setState(() {
          _manualFlag = flag;
        });
        Navigator.pop(context);
        showSuccessSnackBar(context, 'Flag set to: $label');
        // Show summary again after setting flag
        _showSessionSummary();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getManualFlagColor(String flag) {
    switch (flag) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow.shade700;
      case 'green':
      default:
        return Colors.green;
    }
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.none:
        return Colors.green;
      case RiskLevel.low:
        return Colors.yellow.shade700;
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
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

enum MessageStatus { sending, sent, failed }

class ChatMessage {
  final String text;
  final bool isClient;
  final bool isSystem;
  final DateTime timestamp;
  final String? clientMessageId; // For tracking optimistic messages
  MessageStatus status; // Track message sending status

  ChatMessage({
    required this.text,
    required this.isClient,
    required this.isSystem,
    required this.timestamp,
    this.clientMessageId,
    this.status = MessageStatus.sent, // Default to sent for received messages
  });
}
