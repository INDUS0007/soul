import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:common/api/api_client.dart';

class AffirmationsPage extends StatefulWidget {
  const AffirmationsPage({super.key});

  @override
  State<AffirmationsPage> createState() => _AffirmationsPageState();
}

class _AffirmationsPageState extends State<AffirmationsPage> {
  final ApiClient _api = ApiClient();
  
  List<Map<String, dynamic>> _affirmations = [];
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAffirmations();
  }

  Future<void> _loadAffirmations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _api.getAffirmations();
      if (!mounted) return;
      
      final affirmationsList = response['affirmations'] as List<dynamic>? ?? [];
      
      setState(() {
        _affirmations = affirmationsList.map((a) {
          if (a is Map<String, dynamic>) return a;
          if (a is String) return {'text': a, 'author': '', 'category': 'general'};
          return {'text': a.toString(), 'author': '', 'category': 'general'};
        }).toList();
        _loading = false;
        _currentIndex = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        // Fallback affirmations
        _affirmations = [
          {'text': 'I am worthy of care and respect.', 'author': '', 'category': 'self-love'},
          {'text': 'I breathe in calm and exhale tension.', 'author': '', 'category': 'calm'},
          {'text': 'I am capable of handling what comes my way.', 'author': '', 'category': 'strength'},
          {'text': 'I give myself permission to rest and heal.', 'author': '', 'category': 'healing'},
        ];
      });
    }
  }

  void _next() {
    if (_affirmations.isEmpty) return;
    setState(() => _currentIndex = (_currentIndex + 1) % _affirmations.length);
  }

  void _prev() {
    if (_affirmations.isEmpty) return;
    setState(() => _currentIndex = (_currentIndex - 1 + _affirmations.length) % _affirmations.length);
  }

  String get _currentText {
    if (_affirmations.isEmpty) return 'Loading...';
    final aff = _affirmations[_currentIndex];
    return aff['text']?.toString() ?? '';
  }

  String get _currentAuthor {
    if (_affirmations.isEmpty) return '';
    final aff = _affirmations[_currentIndex];
    return aff['author']?.toString() ?? '';
  }

  void _copyCurrent() {
    Clipboard.setData(ClipboardData(text: _currentText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Affirmation copied to clipboard'),
        backgroundColor: Color(0xFF8B5FBF),
      ),
    );
  }

  void _shareMock() {
    final text = _currentAuthor.isNotEmpty 
        ? '"$_currentText"\n— $_currentAuthor'
        : '"$_currentText"';
    
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Share'),
        content: Text('Share this affirmation:\n\n$text'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied for sharing')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text(
          'Daily Affirmations',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5FBF),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
            )
          : RefreshIndicator(
              onRefresh: _loadAffirmations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Main affirmation card
                    _buildMainCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Progress indicator
                    if (_affirmations.isNotEmpty) _buildProgressIndicator(),
                    
                    const SizedBox(height: 24),
                    
                    // Tips card
                    _buildTipsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainCard() {
    return Card(
      elevation: 4,
      shadowColor: const Color(0xFF8B5FBF).withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Category badge
            if (_affirmations.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (_affirmations[_currentIndex]['category'] ?? 'general').toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B5FBF),
                    letterSpacing: 1,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Quote icon
            const Icon(
              Icons.format_quote,
              size: 32,
              color: Color(0xFFD4B8FF),
            ),
            
            const SizedBox(height: 16),
            
            // Affirmation text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                _currentText,
                key: ValueKey<int>(_currentIndex),
                style: const TextStyle(
                  fontSize: 22,
                  color: Color(0xFF2D1B4E),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Author if present
            if (_currentAuthor.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '— $_currentAuthor',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            const SizedBox(height: 28),
            
            // Navigation and action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous button
                _buildCircleButton(
                  icon: Icons.arrow_back_ios_new,
                  onPressed: _prev,
                  tooltip: 'Previous',
                ),
                
                const SizedBox(width: 16),
                
                // Copy button
                _buildCircleButton(
                  icon: Icons.copy_rounded,
                  onPressed: _copyCurrent,
                  tooltip: 'Copy',
                  small: true,
                ),
                
                const SizedBox(width: 12),
                
                // Share button
                _buildCircleButton(
                  icon: Icons.share_rounded,
                  onPressed: _shareMock,
                  tooltip: 'Share',
                  small: true,
                ),
                
                const SizedBox(width: 16),
                
                // Next button
                _buildCircleButton(
                  icon: Icons.arrow_forward_ios,
                  onPressed: _next,
                  tooltip: 'Next',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool small = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: small ? Colors.grey[100] : const Color(0xFF8B5FBF),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: small ? 40 : 48,
            height: small ? 40 : 48,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: small ? 18 : 22,
              color: small ? Colors.grey[700] : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Text(
          '${_currentIndex + 1} of ${_affirmations.length}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _affirmations.length,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5FBF)),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: Color(0xFFFFB74D), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tip',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Read each affirmation slowly. Take a deep breath and repeat it to yourself. Use the arrows to browse through all affirmations.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
