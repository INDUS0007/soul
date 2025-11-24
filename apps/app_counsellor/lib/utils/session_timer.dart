import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utility class for managing session duration timers with backend sync
class SessionTimer {
  final int? sessionId;
  final Future<int> Function(int sessionId) fetchDurationFromBackend;
  final ValueChanged<int> onDurationUpdate;
  
  Timer? _pollTimer;
  bool _isActive = false;
  
  SessionTimer({
    required this.sessionId,
    required this.fetchDurationFromBackend,
    required this.onDurationUpdate,
  });
  
  /// Start polling duration from backend every 2 seconds
  void start() {
    if (_isActive || sessionId == null) return;
    
    _isActive = true;
    _pollTimer?.cancel();
    
    // Fetch immediately
    _fetchDuration();
    
    // Then poll every 2 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isActive) {
        _fetchDuration();
      }
    });
  }
  
  /// Stop polling
  void stop() {
    _isActive = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }
  
  Future<void> _fetchDuration() async {
    if (sessionId == null || !_isActive) return;
    
    try {
      final duration = await fetchDurationFromBackend(sessionId!);
      if (_isActive) {
        onDurationUpdate(duration);
      }
    } catch (e) {
      debugPrint('Error fetching session duration: $e');
    }
  }
  
  void dispose() {
    stop();
  }
}

/// Format duration in seconds to HH:MM:SS string
String formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

/// Format DateTime to HH:MM string
String formatTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

