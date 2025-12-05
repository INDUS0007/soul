import 'dart:async';
import 'package:flutter/material.dart';
import 'package:common/api/api_client.dart';

class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key});

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  
  late AnimationController _controller;
  Timer? _countdownTimer;
  
  bool _running = false;
  bool _expanding = true; // true = inhale, false = exhale
  
  int _inhaleSeconds = 4;
  int _exhaleSeconds = 4;
  int _holdSeconds = 0;
  
  int _countdown = 0;
  int _cyclesCompleted = 0;
  int _totalDurationSeconds = 0;
  
  DateTime? _sessionStartTime;
  
  String _currentPhase = 'Ready';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _inhaleSeconds),
    );
    _controller.addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (!_running) return;
    
    if (status == AnimationStatus.completed) {
      // Finished inhale, start hold or exhale
      if (_holdSeconds > 0 && _expanding) {
        _startHold();
      } else {
        _startExhale();
      }
    } else if (status == AnimationStatus.dismissed) {
      // Finished exhale, start new cycle
      _cyclesCompleted++;
      _startInhale();
    }
  }

  void _startInhale() {
    if (!_running) return;
    setState(() {
      _expanding = true;
      _currentPhase = 'Inhale';
      _countdown = _inhaleSeconds;
    });
    _controller.duration = Duration(seconds: _inhaleSeconds);
    _controller.forward(from: 0.0);
    _startCountdownTimer(_inhaleSeconds);
  }

  void _startHold() {
    if (!_running) return;
    setState(() {
      _currentPhase = 'Hold';
      _countdown = _holdSeconds;
    });
    _startCountdownTimer(_holdSeconds, onComplete: _startExhale);
  }

  void _startExhale() {
    if (!_running) return;
    setState(() {
      _expanding = false;
      _currentPhase = 'Exhale';
      _countdown = _exhaleSeconds;
    });
    _controller.duration = Duration(seconds: _exhaleSeconds);
    _controller.reverse(from: 1.0);
    _startCountdownTimer(_exhaleSeconds);
  }

  void _startCountdownTimer(int seconds, {VoidCallback? onComplete}) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_running) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
          _totalDurationSeconds++;
        } else {
          timer.cancel();
          onComplete?.call();
        }
      });
    });
  }

  void _start() {
    setState(() {
      _running = true;
      _cyclesCompleted = 0;
      _totalDurationSeconds = 0;
      _sessionStartTime = DateTime.now();
    });
    _startInhale();
  }

  void _stop() async {
    _countdownTimer?.cancel();
    _controller.stop();
    _controller.reset();
    
    final wasRunning = _running;
    final duration = _totalDurationSeconds;
    final cycles = _cyclesCompleted;
    
    setState(() {
      _running = false;
      _expanding = true;
      _currentPhase = 'Ready';
      _countdown = 0;
    });
    
    // Save session to database if we had some activity
    if (wasRunning && duration > 0) {
      await _saveSession(duration, cycles);
    }
  }

  Future<void> _saveSession(int duration, int cycles) async {
    try {
      await _api.saveBreathingSession(
        technique: 'deep',
        durationSeconds: duration,
        cyclesCompleted: cycles,
        inhaleSeconds: _inhaleSeconds,
        holdSeconds: _holdSeconds,
        exhaleSeconds: _exhaleSeconds,
        completed: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session saved! $cycles cycles, ${_formatDuration(duration)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save breathing session: $e');
      // Don't show error to user - silent fail for now
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing Exercise'),
        backgroundColor: const Color(0xFF7B61D9),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Main breathing card
            _buildBreathingCard(),
            
            const SizedBox(height: 20),
            
            // Settings card
            if (!_running) _buildSettingsCard(),
            
            // Stats while running
            if (_running) _buildRunningStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Guided Breathing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _running 
                ? 'Follow the circle and countdown timer'
                : 'Set your inhale and exhale times, then press Start.',
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Breathing circle with countdown
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = _controller.value;
                  final scale = 0.6 + (0.4 * t);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _getPhaseColors(),
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getPhaseColors()[0].withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPhase,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (_running) ...[
                              const SizedBox(height: 8),
                              Text(
                                '$_countdown',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _running ? null : _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _running ? _stop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop & Save'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Breathing Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // Inhale duration
            _buildDurationSelector(
              label: 'Inhale Duration',
              value: _inhaleSeconds,
              onChanged: (v) => setState(() => _inhaleSeconds = v),
              color: const Color(0xFF4CAF50),
            ),
            
            const SizedBox(height: 12),
            
            // Hold duration (optional)
            _buildDurationSelector(
              label: 'Hold Duration (optional)',
              value: _holdSeconds,
              onChanged: (v) => setState(() => _holdSeconds = v),
              color: const Color(0xFFFF9800),
              minValue: 0,
            ),
            
            const SizedBox(height: 12),
            
            // Exhale duration
            _buildDurationSelector(
              label: 'Exhale Duration',
              value: _exhaleSeconds,
              onChanged: (v) => setState(() => _exhaleSeconds = v),
              color: const Color(0xFF2196F3),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            Text(
              'Tip: For calm, try 4-4-4 (box breathing) or 4-7-8 for sleep. '
              'If you feel lightheaded, stop and return to normal breathing.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required Color color,
    int minValue = 1,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: value > minValue
                    ? () => onChanged(value - 1)
                    : null,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '${value}s',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: value < 15
                    ? () => onChanged(value + 1)
                    : null,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRunningStats() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFFF3E5F5),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.loop,
              value: '$_cyclesCompleted',
              label: 'Cycles',
            ),
            _buildStatItem(
              icon: Icons.timer,
              value: _formatDuration(_totalDurationSeconds),
              label: 'Duration',
            ),
            _buildStatItem(
              icon: Icons.air,
              value: '$_inhaleSeconds-$_holdSeconds-$_exhaleSeconds',
              label: 'Pattern',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7B61D9), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7B61D9),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  List<Color> _getPhaseColors() {
    switch (_currentPhase) {
      case 'Inhale':
        return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
      case 'Hold':
        return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
      case 'Exhale':
        return [const Color(0xFF2196F3), const Color(0xFF64B5F6)];
      default:
        return [const Color(0xFF9575CD), const Color(0xFFB39DDB)];
    }
  }
}
