import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:common/widgets/widgets.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  String content;
  String? mood;

  JournalEntry({
    required this.id,
    required this.date,
    required this.content,
    this.mood,
  });
}

class MyJournalPage extends StatefulWidget {
  const MyJournalPage({super.key});

  @override
  State<MyJournalPage> createState() => _MyJournalPageState();
}

class _MyJournalPageState extends State<MyJournalPage> {
  final TextEditingController _journalController = TextEditingController();
  String? _selectedMood;
  DateTime _selectedDate = DateTime.now();
  JournalEntry? _editingEntry;
  bool _isEditing = false;

  final List<JournalEntry> _entries = [];

  final Map<String, String> _moods = {
    'Happy': '😊',
    'Calm': '😌',
    'Neutral': '😐',
    'Stressed': '😓',
    'Sad': '😢',
  };

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    final content = _journalController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      if (_isEditing && _editingEntry != null) {
        _editingEntry!.content = content;
        _editingEntry!.mood = _selectedMood;
      } else {
        _entries.insert(
          0,
          JournalEntry(
            id: DateTime.now().toIso8601String(),
            date: _selectedDate,
            content: content,
            mood: _selectedMood,
          ),
        );
      }

      _journalController.clear();
      _selectedMood = null;
      _selectedDate = DateTime.now();
      _editingEntry = null;
      _isEditing = false;
    });

    showSuccessSnackBar(context, 'Journal entry saved');
  }

  void _editEntry(JournalEntry entry) {
    setState(() {
      _isEditing = true;
      _editingEntry = entry;
      _journalController.text = entry.content;
      _selectedMood = entry.mood;
      _selectedDate = entry.date;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B5FBF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getPreviewText(String content) {
    final lines = content.split('\n');
    if (lines.length > 2) {
      return '${lines[0]}\n${lines[1]}...';
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Journal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5FBF),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
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
                  'Your private space to express and reflect.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Dear Self,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: const Text(
                            'Change Date',
                            style: TextStyle(color: Color(0xFF8B5FBF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How are you feeling?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _moods.entries.map((mood) {
                            final isSelected = _selectedMood == mood.key;
                            return InkWell(
                              onTap: () {
                                setState(() => _selectedMood = mood.key);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF8B5FBF).withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF8B5FBF)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      mood.value,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mood.key,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? const Color(0xFF8B5FBF)
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _journalController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText:
                            'Write about your day, emotions, or any thoughts...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F3FF),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5FBF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_isEditing ? 'Update Entry' : 'Save Entry'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_entries.isNotEmpty) ...[
                    const Text(
                      'Previous Entries',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('MMM d, yyyy')
                                            .format(entry.date),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                      if (entry.mood != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          _moods[entry.mood!] ?? '',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getPreviewText(entry.content),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _editEntry(entry),
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 18,
                                      ),
                                      label: const Text('View / Edit'),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF8B5FBF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Writing helps you process emotions — one thought at a time.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

