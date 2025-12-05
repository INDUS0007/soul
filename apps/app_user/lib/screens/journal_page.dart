// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// import 'package:common/widgets/widgets.dart';

// class JournalEntry {
//   final String id;
//   final DateTime date;
//   String content;
//   String? mood;

//   JournalEntry({
//     required this.id,
//     required this.date,
//     required this.content,
//     this.mood,
//   });
// }

// class MyJournalPage extends StatefulWidget {
//   const MyJournalPage({super.key});

//   @override
//   State<MyJournalPage> createState() => _MyJournalPageState();
// }

// class _MyJournalPageState extends State<MyJournalPage> {
//   final TextEditingController _journalController = TextEditingController();
//   String? _selectedMood;
//   DateTime _selectedDate = DateTime.now();
//   JournalEntry? _editingEntry;
//   bool _isEditing = false;

//   final List<JournalEntry> _entries = [];

//   final Map<String, String> _moods = {
//     'Happy': '😊',
//     'Calm': '😌',
//     'Neutral': '😐',
//     'Stressed': '😓',
//     'Sad': '😢',
//   };

//   @override
//   void dispose() {
//     _journalController.dispose();
//     super.dispose();
//   }

//   void _saveEntry() {
//     final content = _journalController.text.trim();
//     if (content.isEmpty) return;

//     setState(() {
//       if (_isEditing && _editingEntry != null) {
//         _editingEntry!.content = content;
//         _editingEntry!.mood = _selectedMood;
//       } else {
//         _entries.insert(
//           0,
//           JournalEntry(
//             id: DateTime.now().toIso8601String(),
//             date: _selectedDate,
//             content: content,
//             mood: _selectedMood,
//           ),
//         );
//       }

//       _journalController.clear();
//       _selectedMood = null;
//       _selectedDate = DateTime.now();
//       _editingEntry = null;
//       _isEditing = false;
//     });

//     showSuccessSnackBar(context, 'Journal entry saved');
//   }

//   void _editEntry(JournalEntry entry) {
//     setState(() {
//       _isEditing = true;
//       _editingEntry = entry;
//       _journalController.text = entry.content;
//       _selectedMood = entry.mood;
//       _selectedDate = entry.date;
//     });
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF8B5FBF),
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }

//   String _getPreviewText(String content) {
//     final lines = content.split('\n');
//     if (lines.length > 2) {
//       return '${lines[0]}\n${lines[1]}...';
//     }
//     return content;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text(
//           'My Journal',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: const Color(0xFF8B5FBF),
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF8B5FBF), Color(0xFF9E8BE3)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(30),
//                 bottomRight: Radius.circular(30),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Your private space to express and reflect.',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Text(
//                       'Dear Self,',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: 20,
//                         fontStyle: FontStyle.italic,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 12,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.1),
//                           spreadRadius: 1,
//                           blurRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.calendar_today, size: 20),
//                         const SizedBox(width: 12),
//                         Text(
//                           DateFormat('MMMM d, yyyy').format(_selectedDate),
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                         const Spacer(),
//                         TextButton(
//                           onPressed: () => _selectDate(context),
//                           child: const Text(
//                             'Change Date',
//                             style: TextStyle(color: Color(0xFF8B5FBF)),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.1),
//                           spreadRadius: 1,
//                           blurRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'How are you feeling?',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: _moods.entries.map((mood) {
//                             final isSelected = _selectedMood == mood.key;
//                             return InkWell(
//                               onTap: () {
//                                 setState(() => _selectedMood = mood.key);
//                               },
//                               borderRadius: BorderRadius.circular(12),
//                               child: Container(
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: isSelected
//                                       ? const Color(0xFF8B5FBF).withOpacity(0.1)
//                                       : Colors.transparent,
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: isSelected
//                                         ? const Color(0xFF8B5FBF)
//                                         : Colors.transparent,
//                                   ),
//                                 ),
//                                 child: Column(
//                                   children: [
//                                     Text(
//                                       mood.value,
//                                       style: const TextStyle(fontSize: 24),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       mood.key,
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         color: isSelected
//                                             ? const Color(0xFF8B5FBF)
//                                             : Colors.grey[600],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.1),
//                           spreadRadius: 1,
//                           blurRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: TextField(
//                       controller: _journalController,
//                       maxLines: 8,
//                       decoration: InputDecoration(
//                         hintText:
//                             'Write about your day, emotions, or any thoughts...',
//                         hintStyle: TextStyle(color: Colors.grey[400]),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide.none,
//                         ),
//                         filled: true,
//                         fillColor: const Color(0xFFF5F3FF),
//                         contentPadding: const EdgeInsets.all(16),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       onPressed: _saveEntry,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF8B5FBF),
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: Text(_isEditing ? 'Update Entry' : 'Save Entry'),
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   if (_entries.isNotEmpty) ...[
//                     const Text(
//                       'Previous Entries',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF333333),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: _entries.length,
//                       itemBuilder: (context, index) {
//                         final entry = _entries[index];
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 16),
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(12),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.grey.withOpacity(0.1),
//                                   spreadRadius: 1,
//                                   blurRadius: 5,
//                                 ),
//                               ],
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(16),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Text(
//                                         DateFormat('MMM d, yyyy')
//                                             .format(entry.date),
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.w600,
//                                           color: Color(0xFF666666),
//                                         ),
//                                       ),
//                                       if (entry.mood != null) ...[
//                                         const SizedBox(width: 8),
//                                         Text(
//                                           _moods[entry.mood!] ?? '',
//                                           style: const TextStyle(fontSize: 16),
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     _getPreviewText(entry.content),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                     style: const TextStyle(
//                                       color: Colors.black87,
//                                       height: 1.5,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 12),
//                                   Align(
//                                     alignment: Alignment.centerRight,
//                                     child: TextButton.icon(
//                                       onPressed: () => _editEntry(entry),
//                                       icon: const Icon(
//                                         Icons.edit,
//                                         size: 18,
//                                       ),
//                                       label: const Text('View / Edit'),
//                                       style: TextButton.styleFrom(
//                                         foregroundColor:
//                                             const Color(0xFF8B5FBF),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                   const SizedBox(height: 20),
//                   Center(
//                     child: Text(
//                       'Writing helps you process emotions — one thought at a time.',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontStyle: FontStyle.italic,
//                         color: Colors.grey[600],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


















import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:common/widgets/widgets.dart';

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

  void _saveEntry() {
    if (_titleController.text.trim().isEmpty ||
        _journalController.text.trim().isEmpty) {
      showErrorSnackBar(context, "Please fill all fields.");
      return;
    }

    setState(() {
      if (_isEditing && _editingEntry != null) {
        _editingEntry!.title = _titleController.text.trim();
        _editingEntry!.content = _journalController.text.trim();
        _editingEntry!.mood = _selectedMood;
        _editingEntry!.entryType = _entryType;
      } else {
        _entries.insert(
          0,
          JournalEntry(
            id: DateTime.now().toIso8601String(),
            date: _selectedDate,
            title: _titleController.text.trim(),
            content: _journalController.text.trim(),
            mood: _selectedMood,
            entryType: _entryType,
          ),
        );
      }

      _titleController.clear();
      _journalController.clear();
      _selectedMood = null;
      _entryType = null;
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