import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:common/widgets/widgets.dart';
import 'package:common/api/api_client.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  String title;
  String content;
  String? mood;
  String? entryType;

  JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.mood,
    this.entryType,
  });
}

class MyJournalPage extends StatefulWidget {
  const MyJournalPage({super.key});

  @override
  State<MyJournalPage> createState() => _MyJournalPageState();
}

class _MyJournalPageState extends State<MyJournalPage> {
  final ApiClient _api = ApiClient();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _journalController = TextEditingController();
  String? _selectedMood;
  String? _entryType;
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

  final List<String> _entryTypes = [
    "Daily Journal",
    "3-Day Journal",
    "Weekly Journal",
    "Reflection",
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadEntriesFromApi();
  }

  Future<void> _loadEntriesFromApi() async {
    try {
      final data = await _api.fetchMyJournalEntries();
      if (!mounted) return;
      setState(() {
        _entries.clear();
        for (final item in data) {
          final id = (item['id'] ?? '').toString();
          final dateStr = (item['date'] ?? '') as String;
          DateTime date;
          try {
            date = DateTime.parse(dateStr);
          } catch (_) {
            date = DateTime.now();
          }
          _entries.add(JournalEntry(
            id: id,
            date: date,
            title: (item['entry'] as String?)?.trim() ?? '',
            content: (item['write_something'] as String?)?.trim() ?? '',
            mood: (item['emoji'] as String?)?.trim() ?? null,
          ));
        }
      });
    } catch (e) {
      // silently ignore for now; UI remains functional offline
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty ||
        _journalController.text.trim().isEmpty) {
      showErrorSnackBar(context, "Please fill all fields.");
      return;
    }

  // Save to server
    final title = _titleController.text.trim();
    final content = _journalController.text.trim();
    final emoji = _selectedMood;
    final date = _selectedDate;

    // optimistic UI: disable button could be added; keep simple
    try {
      await _api.createMyJournalEntry(
        entry: title,
        emoji: emoji,
        date: date,
        writeSomething: content,
      );

      if (!mounted) return;
      // Refresh from server to ensure DB row is present and list is canonical
      await _loadEntriesFromApi();

      // Clear form and show success
      setState(() {
        _titleController.clear();
        _journalController.clear();
        _selectedMood = null;
        _entryType = null;
        _selectedDate = DateTime.now();
        _editingEntry = null;
        _isEditing = false;
      });
      showSuccessSnackBar(context, 'Journal entry saved');
    } catch (err) {
      // Surface API errors to the user for easier debugging
      String message = 'Unable to save entry.';
      try {
        if (err is ApiClientException) {
          message = err.message;
        } else if (err is Exception) {
          message = err.toString();
        }
      } catch (_) {}
      showErrorSnackBar(context, message);
    }
  }

  void _editEntry(JournalEntry entry) {
    setState(() {
      _isEditing = true;
      _editingEntry = entry;
      _titleController.text = entry.title;
      _journalController.text = entry.content;
      _selectedMood = entry.mood;
      _entryType = entry.entryType;
      _selectedDate = entry.date;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'My Journals',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4DB6AC),
        elevation: 1,
      ),

      // MAIN BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // New Entry Card
            _buildNewEntryCard(),

            const SizedBox(height: 30),

            // Heading for previous entries
            if (_entries.isNotEmpty)
              const Text(
                "Your Wellness Journals",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

            const SizedBox(height: 15),

            // List of previous entries
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return _buildEntryCard(entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  // UI: New Entry Card
  Widget _buildNewEntryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "New Journal Entry",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          // Entry Title
          _buildTextField(_titleController, "Entry Title"),

          const SizedBox(height: 15),

          // // Entry Type
          // _buildDropdown(),

          // const SizedBox(height: 15),

          // Mood Selector
          _buildMoodSelector(),

          const SizedBox(height: 15),

          // Date Selector
          _buildDateSelector(),

          const SizedBox(height: 15),

          // Journal Content
          _buildDescriptionField(),

          const SizedBox(height: 25),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DB6AC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(_isEditing ? "Update Entry" : "Save Entry"),
            ),
          ),
        ],
      ),
    );
  }

  // UI: Dropdown
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _entryType,
      decoration: InputDecoration(
        labelText: "Entry Type",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _entryTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) => setState(() => _entryType = value),
    );
  }

  // UI: Mood Selector
  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("How are you feeling?",
            style: TextStyle(fontWeight: FontWeight.w600)),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _moods.entries.map((m) {
            final isSelected = _selectedMood == m.key;

            return GestureDetector(
              onTap: () => setState(() => _selectedMood = m.key),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4DB6AC)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(m.value, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    m.key,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF4DB6AC)
                          : Colors.grey[700],
                      fontSize: 12,
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // UI: Date Selector
  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 10),
            Text(DateFormat("MMM d, yyyy").format(_selectedDate)),
            const Spacer(),
            const Icon(Icons.edit_calendar_outlined),
          ],
        ),
      ),
    );
  }

  // UI: Description Field
  Widget _buildDescriptionField() {
    return TextField(
      controller: _journalController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: "Write something meaningful…",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // UI: Simple TextField
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // UI: Entry Card
  Widget _buildEntryCard(JournalEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + emoji
          Row(
            children: [
              Text(
                entry.mood != null ? _moods[entry.mood] ?? '' : '📝',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Date + Entry Type
          Row(
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(entry.date),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (entry.entryType != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    entry.entryType!,
                    style: const TextStyle(
                      color: Color(0xFF4DB6AC),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Content
          Text(
            entry.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.4),
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _editEntry(entry),
              child: const Text("View / Edit"),
            ),
          )
        ],
      ),
    );
  }
}