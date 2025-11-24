import 'package:flutter/material.dart';
import 'package:common/widgets/widgets.dart';
import '../models/session.dart';
import 'dart:async';

class AudioCallScreen extends StatefulWidget {
  final Session session;

  const AudioCallScreen({super.key, required this.session});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _notesController = TextEditingController();

  late Session _session;
  late AnimationController _pulseController;
  bool _isSessionActive = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  DateTime? _startTime;
  DateTime? _endTime;
  Timer? _timer;
  int _elapsedSeconds = 0;
  RiskLevel _selectedRisk = RiskLevel.none;

  // Manual flag colors
  String _manualFlag = 'green'; // 'green', 'yellow', 'red'

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _selectedRisk = _session.riskLevel;
    _notesController.text = _session.notes ?? '';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startCall() {
    setState(() {
      _isSessionActive = true;
      _startTime = DateTime.now();
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

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Audio call started')));
  }

  void _endCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Audio Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to end this call?'),
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
              _completeCall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }

  void _completeCall() {
    _timer?.cancel();
    _pulseController.stop();

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

    _showSessionSummary();

    // TODO: API call - POST /api/sessions/{id}/end
    // TODO: Close WebRTC connection
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    showSuccessSnackBar(context, _isMuted ? 'Microphone muted' : 'Microphone unmuted');
    // TODO: Mute/unmute audio stream
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    showSuccessSnackBar(context, _isSpeakerOn ? 'Speaker on' : 'Speaker off');
    // TODO: Toggle speaker/earpiece
  }

  void _showSessionSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Call Completed'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('Client', _session.clientName),
              _buildSummaryRow('Type', 'Audio Call'),
              _buildSummaryRow('Started', _formatTime(_startTime!)),
              _buildSummaryRow('Ended', _formatTime(_endTime!)),
              _buildSummaryRow('Duration', _formatDuration(_elapsedSeconds)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Risk Assessment
              Container(
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
      backgroundColor: _isSessionActive
          ? Colors.green.shade50
          : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isSessionActive) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Active Call'),
                  content: const Text('Please end the call before going back'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Client Avatar with Pulse Animation
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width:
                                100 +
                                (_isSessionActive
                                    ? _pulseController.value * 8
                                    : 0),
                            height:
                                100 +
                                (_isSessionActive
                                    ? _pulseController.value * 8
                                    : 0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                if (_isSessionActive)
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius:
                                        15 + (_pulseController.value * 15),
                                    spreadRadius:
                                        3 + (_pulseController.value * 8),
                                  ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                _session.clientName
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Client Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _session.clientName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Call Status
                      Text(
                        _isSessionActive
                            ? 'Call in progress'
                            : 'Ready to start audio call',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Timer
                      if (_isSessionActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            _formatDuration(_elapsedSeconds),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),

                      if (_isSessionActive) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Started at ${_formatTime(_startTime!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        // Manual Risk Level Selection
                        const SizedBox(height: 20),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            color: _getRiskColor(
                              _selectedRisk,
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getRiskColor(
                                _selectedRisk,
                              ).withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showRiskSelectionDialog,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.flag_outlined,
                                          color: _getRiskColor(_selectedRisk),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Risk Assessment',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
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
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to change',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Call Controls
                      if (_isSessionActive) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildControlButton(
                                icon: _isMuted ? Icons.mic_off : Icons.mic,
                                label: _isMuted ? 'Unmute' : 'Mute',
                                onPressed: _toggleMute,
                                isActive: !_isMuted,
                              ),
                              _buildControlButton(
                                icon: _isSpeakerOn
                                    ? Icons.volume_up
                                    : Icons.volume_down,
                                label: 'Speaker',
                                onPressed: _toggleSpeaker,
                                isActive: _isSpeakerOn,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Start/End Call Button
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: _isSessionActive
                            ? FloatingActionButton.extended(
                                onPressed: _endCall,
                                backgroundColor: Colors.red,
                                icon: const Icon(Icons.call_end),
                                label: const Text(
                                  'End Call',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : FloatingActionButton.extended(
                                onPressed: _startCall,
                                backgroundColor: Colors.green,
                                icon: const Icon(Icons.phone),
                                label: const Text(
                                  'Start Call',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = true,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            iconSize: 28,
            color:
                color ??
                (isActive ? Theme.of(context).primaryColor : Colors.grey),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
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
