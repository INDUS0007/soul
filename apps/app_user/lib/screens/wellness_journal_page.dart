// import 'package:flutter/material.dart';

// import 'package:common/api/api_client.dart';

// class WellnessJournalPage extends StatefulWidget {
//   const WellnessJournalPage({super.key});

//   @override
//   State<WellnessJournalPage> createState() => _WellnessJournalPageState();
// }

// class _WellnessJournalPageState extends State<WellnessJournalPage> {
//   final ApiClient _api = ApiClient();
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _noteController = TextEditingController();
//   final List<String> _moods = ['😊', '😐', '😔', '😡', '😴'];
//   final List<String> _entryTypes = ['3-Day Journal', 'Weekly Journal', 'Custom'];

//   bool _loading = true;
//   bool _refreshing = false;
//   bool _saving = false;
//   String? _selectedMood;
//   String _entryType = '3-Day Journal';
//   String? _errorMessage;

//   List<WellnessJournalEntry> _entries = const [];

//   @override
//   void initState() {
//     super.initState();
//     _loadEntries();
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _noteController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadEntries({bool showLoader = true}) async {
//     if (showLoader) {
//       setState(() {
//         _loading = true;
//         _errorMessage = null;
//       });
//     } else {
//       setState(() {
//         _refreshing = true;
//         _errorMessage = null;
//       });
//     }

//     try {
//       final data = await _api.fetchWellnessJournalEntries();
//       if (!mounted) return;
//       setState(() {
//         _entries = data;
//         _loading = false;
//         _refreshing = false;
//       });
//     } on ApiClientException catch (error) {
//       if (!mounted) return;
//       setState(() {
//         _errorMessage = error.message;
//         _loading = false;
//         _refreshing = false;
//       });
//     } catch (error) {
//       if (!mounted) return;
//       setState(() {
//         _errorMessage = 'Unable to load entries. Please try again. ($error)';
//         _loading = false;
//         _refreshing = false;
//       });
//     }
//   }

//   Future<void> _handleRefresh() => _loadEntries(showLoader: false);

//   Future<void> _saveEntry() async {
//     if (_saving) return;

//     final title = _titleController.text.trim();
//     final note = _noteController.text.trim();
//     final mood = _selectedMood;

//     if (title.isEmpty || note.isEmpty || mood == null) {
//       _showSnackBar('Please complete all fields before saving.');
//       return;
//     }

//     setState(() {
//       _saving = true;
//     });
//     FocusScope.of(context).unfocus();

//     try {
//       final entry = await _api.createWellnessJournalEntry(
//         title: title,
//         note: note,
//         mood: mood,
//         entryType: _entryType,
//       );

//       if (!mounted) return;
//       setState(() {
//         _entries = [entry, ..._entries];
//         _titleController.clear();
//         _noteController.clear();
//         _selectedMood = null;
//         _entryType = '3-Day Journal';
//         _saving = false;
//       });

//       _showSnackBar('Entry saved!');
//     } on ApiClientException catch (error) {
//       if (!mounted) return;
//       setState(() {
//         _saving = false;
//       });
//       _showSnackBar(error.message);
//     } catch (error) {
//       if (!mounted) return;
//       setState(() {
//         _saving = false;
//       });
//       _showSnackBar('Unable to save entry. Please try again. ($error)');
//     }
//   }

//   Future<void> _deleteEntry(WellnessJournalEntry entry) async {
//     final shouldDelete = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete entry?'),
//         content: Text(
//           'Are you sure you want to delete "${entry.title}"?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (shouldDelete != true) {
//       return;
//     }

//     try {
//       await _api.deleteWellnessJournalEntry(entry.id);
//       if (!mounted) return;
//       setState(() {
//         _entries = _entries.where((item) => item.id != entry.id).toList();
//       });
//       _showSnackBar('Entry deleted');
//     } on ApiClientException catch (error) {
//       if (!mounted) return;
//       _showSnackBar(error.message);
//     } catch (error) {
//       if (!mounted) return;
//       _showSnackBar('Unable to delete entry. Please try again. ($error)');
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final softTeal = const Color(0xFF4DB6AC);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Wellness Journal'),
//         backgroundColor: softTeal,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Refresh',
//             onPressed: _loading ? null : () => _loadEntries(),
//           ),
//         ],
//       ),
//       backgroundColor: const Color(0xFFFFF8E1),
//       body: SafeArea(
//         child: _buildBody(),
//       ),
//     );
//   }

//   Widget _buildBody() {
//     if (_loading && !_refreshing) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_errorMessage != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 _errorMessage!,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 16),
//               FilledButton(
//                 onPressed: () => _loadEntries(),
//                 child: const Text('Retry'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _handleRefresh,
//       child: ListView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
//         children: [
//           const Text(
//             'Reflect on your journey — these journals are saved securely for you and your wellness team.',
//             style: TextStyle(
//               fontSize: 16,
//               height: 1.5,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 20),
//           _buildEntryForm(),
//           const SizedBox(height: 30),
//           _buildEntriesList(),
//           const SizedBox(height: 20),
//           const Center(
//             child: Text(
//               '“Small reflections each day lead to big changes over time.”',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontStyle: FontStyle.italic,
//                 fontSize: 14,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEntryForm() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'New Journal Entry',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _titleController,
//             textCapitalization: TextCapitalization.sentences,
//             decoration: const InputDecoration(
//               labelText: 'Entry Title',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _noteController,
//             minLines: 4,
//             maxLines: 6,
//             textCapitalization: TextCapitalization.sentences,
//             decoration: const InputDecoration(
//               labelText: 'How are you feeling today?',
//               alignLabelWithHint: true,
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Mood',
//             style: TextStyle(fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 12,
//             children: _moods
//                 .map(
//                   (mood) => ChoiceChip(
//                     label: Text(
//                       mood,
//                       style: const TextStyle(fontSize: 20),
//                     ),
//                     selected: _selectedMood == mood,
//                     onSelected: (selected) {
//                       setState(() {
//                         _selectedMood = selected ? mood : null;
//                       });
//                     },
//                   ),
//                 )
//                 .toList(),
//           ),
//           const SizedBox(height: 16),
//           DropdownButtonFormField<String>(
//             value: _entryType,
//             items: _entryTypes
//                 .map(
//                   (type) => DropdownMenuItem(
//                     value: type,
//                     child: Text(type),
//                   ),
//                 )
//                 .toList(),
//             onChanged: (value) {
//               if (value == null) return;
//               setState(() {
//                 _entryType = value;
//               });
//             },
//             decoration: const InputDecoration(
//               labelText: 'Entry Type',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             child: FilledButton(
//               onPressed: _saving ? null : _saveEntry,
//               child: _saving
//                   ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                   : const Text('Save Entry'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEntriesList() {
//     if (_entries.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: const Color(0xFFEDE7F6),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: const Text(
//           'No journal entries yet. Capture your first reflection above to begin your journey.',
//           style: TextStyle(
//             fontSize: 15,
//             height: 1.5,
//             color: Colors.black87,
//           ),
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Your Wellness Journals',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 12),
//         ..._entries.map(_buildEntryCard),
//       ],
//     );
//   }

//   Widget _buildEntryCard(WellnessJournalEntry entry) {
//     return Card(
//       color: const Color(0xFFEDE7F6),
//       elevation: 2,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Text(
//                     entry.title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 PopupMenuButton<String>(
//                   onSelected: (value) {
//                     if (value == 'delete') {
//                       _deleteEntry(entry);
//                     }
//                   },
//                   itemBuilder: (context) => const [
//                     PopupMenuItem(
//                       value: 'delete',
//                       child: Text('Delete'),
//                     )
//                   ],
//                   icon: const Icon(Icons.more_vert),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Text(
//                   entry.mood,
//                   style: const TextStyle(fontSize: 22),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     entry.formattedDate.isNotEmpty
//                         ? entry.formattedDate
//                         : 'Saved just now',
//                     style: const TextStyle(
//                       fontSize: 13,
//                       color: Colors.black54,
//                     ),
//                   ),
//                 ),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: entry.entryType == '3-Day Journal'
//                         ? const Color(0xFFB2DFDB)
//                         : (entry.entryType == 'Weekly Journal'
//                             ? Colors.amber[100]
//                             : Colors.blue[100]),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   child: Text(
//                     entry.entryType,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               entry.note,
//               style: const TextStyle(
//                 fontSize: 14,
//                 height: 1.5,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }









import 'package:flutter/material.dart';

import 'package:common/api/api_client.dart';

/// Tabbed page: My Journals (user entries) + Publications (live guidance resources)
class WellnessJournalPage extends StatelessWidget {
  const WellnessJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Journals'),
          backgroundColor: const Color(0xFF4DB6AC),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Journals'),
              Tab(text: 'Publications'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyJournalsTab(),
            _PublicationsTab(),
          ],
        ),
      ),
    );
  }
}

class _MyJournalsTab extends StatefulWidget {
  const _MyJournalsTab();

  @override
  State<_MyJournalsTab> createState() => _MyJournalsTabState();
}

class _MyJournalsTabState extends State<_MyJournalsTab> {
  final ApiClient _api = ApiClient();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final List<String> _moods = ['😊', '😐', '😔', '😡', '😴'];
  final List<String> _entryTypes = ['3-Day Journal', 'Weekly Journal', 'Custom'];

  bool _loading = true;
  bool _refreshing = false;
  bool _saving = false;
  String? _selectedMood;
  String _entryType = '3-Day Journal';
  String? _errorMessage;

  List<dynamic> _entries = const [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _refreshing = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _api.fetchWellnessJournalEntries();
      if (!mounted) return;
      setState(() {
        _entries = data;
        _loading = false;
        _refreshing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is Exception ? error.toString() : 'Unable to load entries.';
        _loading = false;
        _refreshing = false;
      });
    }
  }

  Future<void> _handleRefresh() => _loadEntries(showLoader: false);

  Future<void> _saveEntry() async {
    if (_saving) return;

    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final mood = _selectedMood;

    if (title.isEmpty || note.isEmpty || mood == null) {
      _showSnackBar('Please complete all fields before saving.');
      return;
    }

    setState(() {
      _saving = true;
    });
    FocusScope.of(context).unfocus();

    try {
      final entry = await _api.createWellnessJournalEntry(
        title: title,
        note: note,
        mood: mood,
        entryType: _entryType,
      );

      if (!mounted) return;
      setState(() {
        _entries = [entry, ..._entries];
        _titleController.clear();
        _noteController.clear();
        _selectedMood = null;
        _entryType = '3-Day Journal';
        _saving = false;
      });

      _showSnackBar('Entry saved!');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      _showSnackBar('Unable to save entry. Please try again. ($error)');
    }
  }

  Future<void> _deleteEntry(dynamic entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Are you sure you want to delete "${entry.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _api.deleteWellnessJournalEntry(entry.id);
      if (!mounted) return;
      setState(() {
        _entries = _entries.where((item) => item.id != entry.id).toList();
      });
      _showSnackBar('Entry deleted');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Unable to delete entry. Please try again. ($error)');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: _buildBody());
  }

  Widget _buildBody() {
    if (_loading && !_refreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)), const SizedBox(height: 16), FilledButton(onPressed: () => _loadEntries(), child: const Text('Retry'))]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
        const Text('Reflect on your journey — these journals are saved securely for you and your wellness team.', style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
        const SizedBox(height: 20),
        _buildEntryForm(),
        const SizedBox(height: 30),
        _buildEntriesList(),
        const SizedBox(height: 20),
        const Center(child: Text('“Small reflections each day lead to big changes over time.”', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: Colors.black87))),
      ]),
    );
  }

  Widget _buildEntryForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('New Journal Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        TextField(controller: _titleController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Entry Title', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _noteController, minLines: 4, maxLines: 6, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'How are you feeling today?', alignLabelWithHint: true, border: OutlineInputBorder())),
        const SizedBox(height: 16),
        const Text('Mood', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, children: _moods.map((mood) => ChoiceChip(label: Text(mood, style: const TextStyle(fontSize: 20)), selected: _selectedMood == mood, onSelected: (selected) => setState(() => _selectedMood = selected ? mood : null))).toList()),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: _entryType, items: _entryTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(), onChanged: (value) { if (value == null) return; setState(() => _entryType = value); }, decoration: const InputDecoration(labelText: 'Entry Type', border: OutlineInputBorder())),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _saving ? null : _saveEntry, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Save Entry'))),
      ]),
    );
  }

  Widget _buildEntriesList() {
    if (_entries.isEmpty) {
      return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(16)), child: const Text('No journal entries yet. Capture your first reflection above to begin your journey.', style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Your Wellness Journals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ..._entries.map(_buildEntryCard),
    ]);
  }

  Widget _buildEntryCard(dynamic entry) {
    return Card(
      color: const Color(0xFFEDE7F6),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(entry.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            PopupMenuButton<String>(onSelected: (value) { if (value == 'delete') _deleteEntry(entry); }, itemBuilder: (context) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))], icon: const Icon(Icons.more_vert)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text(entry.mood, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(child: Text(entry.formattedDate.isNotEmpty ? entry.formattedDate : 'Saved just now', style: const TextStyle(fontSize: 13, color: Colors.black54))),
            Container(decoration: BoxDecoration(color: entry.entryType == '3-Day Journal' ? const Color(0xFFB2DFDB) : (entry.entryType == 'Weekly Journal' ? Colors.amber[100] : Colors.blue[100]), borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text(entry.entryType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          ]),
          const SizedBox(height: 12),
          Text(entry.note, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
        ]),
      ),
    );
  }
}

class _PublicationsTab extends StatefulWidget {
  const _PublicationsTab();

  @override
  State<_PublicationsTab> createState() => _PublicationsTabState();
}

class _PublicationsTabState extends State<_PublicationsTab> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<GuidanceResourceItem> _items = [];
  String _filter = 'recent';
  String? _categoryFilter;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await _api.fetchGuidanceResources();

      // Convert response resources to typed GuidanceResourceItem, allow growable list
      final list = (resp.resources as List<dynamic>)
          .map<GuidanceResourceItem>((e) {
        if (e is GuidanceResourceItem) return e;
        if (e is Map<String, dynamic>) return GuidanceResourceItem.fromJson(e);
        // Fallback: try to treat as dynamic and build minimal item
        try {
          final map = Map<String, dynamic>.from(e as Map);
          return GuidanceResourceItem.fromJson(map);
        } catch (_) {
          return GuidanceResourceItem(
            id: -9999,
            type: 'article',
            title: '',
            subtitle: '',
            summary: '',
            category: '',
            duration: '',
            mediaUrl: '',
            thumbnail: '',
            isFeatured: false,
          );
        }
      }).toList(growable: true);

      // If there's no ongoing 'Soul Support' publication, prepend a seeded one
      final hasSoul = list.any((e) => e.title.toLowerCase().contains('soul'));

      if (!hasSoul) {
        final seedItem = GuidanceResourceItem(
          id: -9999,
          type: 'article',
          title: 'Soul Support: Ongoing Help & Resources',
          subtitle: 'Practical support, updated regularly',
          summary:
              'Soul Support is our ongoing initiative offering short articles, exercises and contact points to help you through stressful moments. We update this collection regularly with new guidance and community resources.',
          category: 'support',
          duration: '',
          mediaUrl: '',
          thumbnail: 'https://via.placeholder.com/400x240.png?text=Soul+Support',
          isFeatured: true,
        );
        list.insert(0, seedItem);
      }

      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
        _loading = false;
      });
    }
  }

  List<GuidanceResourceItem> get _filteredItems {
    var list = _items;
    if (_filter == 'featured') {
      list = list.where((e) => e.isFeatured).toList();
    }
    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      list = list.where((e) => (e.category) == _categoryFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) {
        final title = (e.title).toString().toLowerCase();
        final summary = (e.summary).toString().toLowerCase();
        return title.contains(q) || summary.contains(q);
      }).toList();
    }
    return list;
  }

  void _openDetail(GuidanceResourceItem item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _PublicationDetailPage(resource: item)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadItems,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 6),
          const Text('Recently updated publications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Browse the latest journal articles and resources published by our experts.', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Search publications', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onChanged: (v) => setState(() => _search = v))),
            const SizedBox(width: 12),
            PopupMenuButton<String>(icon: const Icon(Icons.filter_list), onSelected: (v) => setState(() => _filter = v), itemBuilder: (_) => [const PopupMenuItem(value: 'recent', child: Text('Recent')), const PopupMenuItem(value: 'featured', child: Text('Featured'))]),
          ]),
          const SizedBox(height: 12),
          if (_loading) ...[const SizedBox(height: 40), const Center(child: CircularProgressIndicator())] else if (_error != null) ...[
            const SizedBox(height: 20),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text('Failed to load: $_error'), const SizedBox(height: 8), ElevatedButton(onPressed: _loadItems, child: const Text('Retry'))]))),
          ] else ...[
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final resource = _filteredItems[index];
                final title = resource.title.toString();
                final subtitle = (resource.subtitle.toString().isNotEmpty ? resource.subtitle.toString() : resource.summary.toString());
                final thumb = resource.thumbnail.toString();
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    onTap: () => _openDetail(resource),
                    leading: thumb.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(thumb, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.article))) : const Icon(Icons.article, size: 44, color: Colors.grey),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _PublicationDetailPage extends StatelessWidget {
  final GuidanceResourceItem resource;

  const _PublicationDetailPage({required this.resource});

  @override
  Widget build(BuildContext context) {
    final title = resource.title.toString();
    final summary = (resource.summary.isNotEmpty ? resource.summary : resource.subtitle).toString();
    final media = resource.mediaUrl.toString();
    final thumbnail = resource.thumbnail.toString();

    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: const Color(0xFF8B5FBF)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (thumbnail.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(thumbnail, fit: BoxFit.cover, width: double.infinity, height: 180, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 12),
          if (media.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final uri = Uri.tryParse(media);
                  if (uri == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid media URL')));
                    return;
                  }
                  // URL launching not available (url_launcher package not in dependencies)
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open media')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to open media: $e')));
                }
              },
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Open Media'),
            ),
        ]),
      ),
    );
  }
}