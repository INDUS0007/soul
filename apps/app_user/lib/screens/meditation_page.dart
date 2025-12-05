// import 'package:flutter/material.dart';

// import 'package:common/api/api_client.dart';
// import 'package:common/widgets/widgets.dart';

// class MeditationPage extends StatefulWidget {
//   const MeditationPage({super.key});

//   @override
//   State<MeditationPage> createState() => _MeditationPageState();
// }

// class _MeditationPageState extends State<MeditationPage> {
//   final ApiClient _api = ApiClient();

//   bool _loading = true;
//   String? _error;
//   MeditationSessionsResponse? _response;
//   String _selectedCategory = 'All';
//   String _selectedDifficulty = 'All';

//   @override
//   void initState() {
//     super.initState();
//     _loadSessions();
//   }

//   Future<void> _loadSessions() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       final response = await _api.fetchMeditationSessions();
//       if (!mounted) return;
//       setState(() {
//         _response = response;
//         _loading = false;
//       });
//     } on ApiClientException catch (error) {
//       if (!mounted) return;
//       setState(() {
//         _error = error.message;
//         _loading = false;
//       });
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         _error = 'Unable to load meditations right now.';
//         _loading = false;
//       });
//     }
//   }

//   List<MeditationSessionItem> get _filteredSessions {
//     final response = _response;
//     if (response == null) return const [];

//     Iterable<MeditationSessionItem> sessions = response.sessions;
//     if (_selectedCategory != 'All') {
//       sessions = response.groupedByCategory[_selectedCategory] ?? const [];
//     }
//     if (_selectedDifficulty != 'All') {
//       sessions = sessions
//           .where((session) => session.difficulty == _selectedDifficulty);
//     }
//     return sessions.toList(growable: false);
//   }

//   Set<String> get _difficultyOptions {
//     final response = _response;
//     if (response == null) {
//       return {'All'};
//     }
//     final difficulties =
//         response.sessions.map((s) => s.difficulty).where((d) => d.isNotEmpty);
//     return {'All', ...difficulties};
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final isWide = size.width > 600;

//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text('Meditation'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new),
//           onPressed: () => Navigator.of(context).maybePop(),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF1D8F97), Color(0xFF6C4CB5), Color(0xFF162A6C)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: SafeArea(
//           child: RefreshIndicator(
//             onRefresh: _loadSessions,
//             child: ListView(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//               children: [
//                 _buildHeading(context),
//                 const SizedBox(height: 16),
//                 if (_response?.categories.isNotEmpty ?? false)
//                   _buildCategoryWrap(isWide, size.width),
//                 if (_response != null) ...[
//                   const SizedBox(height: 12),
//                   _DifficultySelector(
//                     options: _difficultyOptions.toList(),
//                     selected: _selectedDifficulty,
//                     onSelected: (value) {
//                       setState(() => _selectedDifficulty = value);
//                     },
//                   ),
//                 ],
//                 if (_loading) ...[
//                   const SizedBox(height: 48),
//                   const Center(child: CircularProgressIndicator()),
//                 ] else if (_error != null) ...[
//                   const SizedBox(height: 32),
//                   _ErrorState(message: _error!, onRetry: _loadSessions),
//                 ] else if (_filteredSessions.isEmpty) ...[
//                   const SizedBox(height: 48),
//                   const _EmptyState(
//                     message:
//                         'No meditations found. Try a different category or difficulty.',
//                   ),
//                 ] else ...[
//                   const SizedBox(height: 20),
//                   ..._filteredSessions.map(
//                     (session) => _MeditationCard(
//                       session: session,
//                       onTap: () => _openSessionDetails(context, session),
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 32),
//                 _ClassesSection(onBook: (plan) {
//                   showSuccessSnackBar(context, 'Booking flow for $plan coming soon.');
//                 }),
//                 const SizedBox(height: 28),
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(18),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: const Text(
//                     '“Take a deep breath. Calmness begins the moment you decide to pause.”',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeading(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'AI-powered calm',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           'Experience personalised meditation sessions curated by experts and guided by AI-generated audio.',
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.85),
//             fontSize: 16,
//             height: 1.4,
//           ),
//         ),
//         if (_response?.featured.isNotEmpty ?? false) ...[
//           const SizedBox(height: 24),
//           const Text(
//             'Featured sessions',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 12),
//           SizedBox(
//             height: 170,
//             child: ListView.separated(
//               scrollDirection: Axis.horizontal,
//               itemCount: _response!.featured.length,
//               separatorBuilder: (_, __) => const SizedBox(width: 12),
//               itemBuilder: (context, index) {
//                 final session = _response!.featured[index];
//                 return _FeaturedSessionCard(
//                   session: session,
//                   onTap: () => _openSessionDetails(context, session),
//                 );
//               },
//             ),
//           ),
//         ],
//         const SizedBox(height: 24),
//         const Text(
//           'Select a meditation',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 12),
//       ],
//     );
//   }

//   Widget _buildCategoryWrap(bool isWide, double width) {
//     final categories = ['All', ...?_response?.categories];
//     final cardWidth =
//         isWide ? (width - 80) / 3 : (width - 56) / 2; // replicating layout
//     return Wrap(
//       spacing: 16,
//       runSpacing: 16,
//       children: categories.map((category) {
//         final selected = category == _selectedCategory;
//         return InkWell(
//           onTap: () {
//             setState(() {
//               _selectedCategory = category;
//             });
//           },
//           borderRadius: BorderRadius.circular(18),
//           child: Container(
//             width: cardWidth,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: selected
//                   ? Colors.white.withOpacity(0.28)
//                   : Colors.white.withOpacity(0.18),
//               borderRadius: BorderRadius.circular(18),
//               border: Border.all(
//                 color: selected
//                     ? Colors.white
//                     : Colors.white.withOpacity(0.2),
//               ),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   _iconForCategory(category),
//                   color: Colors.white,
//                   size: 36,
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   category,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   IconData _iconForCategory(String category) {
//     switch (category.toLowerCase()) {
//       case 'sleep':
//         return Icons.nights_stay;
//       case 'focus':
//         return Icons.center_focus_strong;
//       case 'gratitude':
//         return Icons.favorite;
//       case 'breathing':
//         return Icons.air;
//       case 'emotional':
//         return Icons.sentiment_satisfied_alt;
//       default:
//         return Icons.self_improvement;
//     }
//   }

//   void _openSessionDetails(BuildContext context, MeditationSessionItem session) {
//     showModalBottomSheet<void>(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (context) => Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.deepPurple.withOpacity(0.12),
//                   child: Icon(
//                     _iconForCategory(session.category),
//                     color: Colors.deepPurple,
//                     size: 28,
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         session.title,
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.w700,
//                             ),
//                       ),
//                       if (session.subtitle.isNotEmpty)
//                         Text(session.subtitle),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             if (session.description.isNotEmpty)
//               Text(
//                 session.description,
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyMedium
//                     ?.copyWith(height: 1.5),
//               ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Chip(
//                   avatar: const Icon(Icons.timer_outlined, size: 18),
//                   label: Text('${session.durationMinutes} min'),
//                 ),
//                 const SizedBox(width: 8),
//                 Chip(
//                   avatar: const Icon(Icons.flag_outlined, size: 18),
//                   label: Text(session.difficulty),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             FilledButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 showSuccessSnackBar(context, 'Playing "${session.title}" (demo preview)…');
//               },
//               icon: const Icon(Icons.play_arrow),
//               label: const Text('Start Session'),
//             ),
//             if (session.audioUrl.isNotEmpty)
//               TextButton.icon(
//                 onPressed: () {
//                   showSuccessSnackBar(context, 'Opening audio URL (demo)…');
//                 },
//                 icon: const Icon(Icons.headphones),
//                 label: const Text('Listen'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _MeditationCard extends StatelessWidget {
//   const _MeditationCard({required this.session, required this.onTap});

//   final MeditationSessionItem session;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       color: Colors.white.withOpacity(0.18),
//       child: ListTile(
//         onTap: onTap,
//         leading: Icon(
//           Icons.self_improvement,
//           color: Colors.white.withOpacity(0.9),
//           size: 32,
//         ),
//         title: Text(
//           session.title,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         subtitle: Text(
//           [
//             session.category,
//             '${session.durationMinutes} min',
//             session.difficulty,
//           ].join(' • '),
//           style: TextStyle(color: Colors.white.withOpacity(0.85)),
//         ),
//         trailing: const Icon(
//           Icons.chevron_right,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }
// }

// class _FeaturedSessionCard extends StatelessWidget {
//   const _FeaturedSessionCard({required this.session, required this.onTap});

//   final MeditationSessionItem session;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 220,
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.18),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.white.withOpacity(0.2)),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               session.title,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const Spacer(),
//             Text(
//               '${session.durationMinutes} min • ${session.difficulty}',
//               style: TextStyle(color: Colors.white.withOpacity(0.85)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _DifficultySelector extends StatelessWidget {
//   const _DifficultySelector({
//     required this.options,
//     required this.selected,
//     required this.onSelected,
//   });

//   final List<String> options;
//   final String selected;
//   final ValueChanged<String> onSelected;

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: options.map((option) {
//           final isSelected = option == selected;
//           return Padding(
//             padding: const EdgeInsets.only(right: 8),
//             child: ChoiceChip(
//               label: Text(option),
//               selected: isSelected,
//               onSelected: (_) => onSelected(option),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// class _ErrorState extends StatelessWidget {
//   const _ErrorState({required this.message, required this.onRetry});

//   final String message;
//   final VoidCallback onRetry;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
//         const SizedBox(height: 12),
//         Text(
//           message,
//           textAlign: TextAlign.center,
//           style: const TextStyle(color: Colors.white),
//         ),
//         const SizedBox(height: 12),
//         TextButton.icon(
//           onPressed: onRetry,
//           icon: const Icon(Icons.refresh),
//           label: const Text('Retry'),
//         ),
//       ],
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   const _EmptyState({required this.message});

//   final String message;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const Icon(Icons.hourglass_empty, size: 48, color: Colors.white),
//         const SizedBox(height: 12),
//         Text(
//           message,
//           textAlign: TextAlign.center,
//           style: const TextStyle(color: Colors.white),
//         ),
//       ],
//     );
//   }
// }

// class _ClassesSection extends StatelessWidget {
//   const _ClassesSection({required this.onBook});

//   final void Function(String planName) onBook;

//   @override
//   Widget build(BuildContext context) {
//     final classOptions = [
//       _ClassOption(
//         title: 'One-Day Class',
//         description: 'Join a single guided session for quick relaxation.',
//         icon: Icons.event_available,
//       ),
//       _ClassOption(
//         title: 'Regular Plan',
//         description: 'Create weekly practice with live instructors.',
//         icon: Icons.repeat,
//       ),
//       _ClassOption(
//         title: 'Online Video Sessions',
//         description: 'Attend virtual meditation classes at your convenience.',
//         icon: Icons.videocam,
//       ),
//     ];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Meditation Classes (paid sessions)',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 22,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Schedule sessions with certified trainers. Previews below are placeholders.',
//           style: TextStyle(color: Colors.white.withOpacity(0.85)),
//         ),
//         const SizedBox(height: 12),
//         ...classOptions.map(
//           (option) => Padding(
//             padding: const EdgeInsets.only(bottom: 16),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.14),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: Colors.white.withOpacity(0.2)),
//               ),
//               child: ListTile(
//                 leading: Icon(option.icon, color: Colors.white, size: 32),
//                 title: Text(
//                   option.title,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 subtitle: Text(
//                   option.description,
//                   style: TextStyle(color: Colors.white.withOpacity(0.85)),
//                 ),
//                 trailing: ElevatedButton(
//                   onPressed: () => onBook(option.title),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     foregroundColor: const Color(0xFF1D8F97),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   child: const Text('Book'),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ClassOption {
//   const _ClassOption({
//     required this.title,
//     required this.description,
//     required this.icon,
//   });

//   final String title;
//   final String description;
//   final IconData icon;
// }

import 'package:flutter/material.dart';

class MeditationPage extends StatefulWidget {
  const MeditationPage({super.key});

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

// class _MeditationPageState extends State<MeditationPage> {
//   final ApiClient _api = ApiClient();

//   bool _loading = true;
//   String? _error;
//   MeditationSessionsResponse? _response;
//   String _selectedCategory = 'All';
//   String _selectedDifficulty = 'All';

//   @override
//   void initState() {
//     super.initState();
//     _loadSessions();
//   }

//   Future<void> _loadSessions() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       final response = await _api.fetchMeditationSessions();
//       if (!mounted) return;
//       setState(() {
//         _response = response;
//         _loading = false;
//       });
//     } on ApiClientException catch (error) {
//       if (!mounted) return;
//       setState(() {
//         _error = error.message;
//         _loading = false;
//       });
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         _error = 'Unable to load meditations right now.';
//         _loading = false;
//       });
//     }
//   }

//   List<MeditationSessionItem> get _filteredSessions {
//     final response = _response;
//     if (response == null) return const [];

//     Iterable<MeditationSessionItem> sessions = response.sessions;
//     if (_selectedCategory != 'All') {
//       sessions = response.groupedByCategory[_selectedCategory] ?? const [];
//     }
//     if (_selectedDifficulty != 'All') {
//       sessions = sessions
//           .where((session) => session.difficulty == _selectedDifficulty);
//     }
//     return sessions.toList(growable: false);
//   }

//   Set<String> get _difficultyOptions {
//     final response = _response;
//     if (response == null) {
//       return {'All'};
//     }
//     final difficulties =
//         response.sessions.map((s) => s.difficulty).where((d) => d.isNotEmpty);
//     return {'All', ...difficulties};
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final isWide = size.width > 600;

//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text('Meditation'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new),
//           onPressed: () => Navigator.of(context).maybePop(),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF1D8F97), Color(0xFF6C4CB5), Color(0xFF162A6C)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: SafeArea(
//           child: RefreshIndicator(
//             onRefresh: _loadSessions,
//             child: ListView(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//               children: [
//                 _buildHeading(context),
//                 const SizedBox(height: 16),
//                 if (_response?.categories.isNotEmpty ?? false)
//                   _buildCategoryWrap(isWide, size.width),
//                 if (_response != null) ...[
//                   const SizedBox(height: 12),
//                   _DifficultySelector(
//                     options: _difficultyOptions.toList(),
//                     selected: _selectedDifficulty,
//                     onSelected: (value) {
//                       setState(() => _selectedDifficulty = value);
//                     },
//                   ),
//                 ],
//                 if (_loading) ...[
//                   const SizedBox(height: 48),
//                   const Center(child: CircularProgressIndicator()),
//                 ] else if (_error != null) ...[
//                   const SizedBox(height: 32),
//                   _ErrorState(message: _error!, onRetry: _loadSessions),
//                 ] else if (_filteredSessions.isEmpty) ...[
//                   const SizedBox(height: 48),
//                   const _EmptyState(
//                     message:
//                         'No meditations found. Try a different category or difficulty.',
//                   ),
//                 ] else ...[
//                   const SizedBox(height: 20),
//                   ..._filteredSessions.map(
//                     (session) => _MeditationCard(
//                       session: session,
//                       onTap: () => _openSessionDetails(context, session),
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 32),
//                 _ClassesSection(onBook: (plan) {
//                   showSuccessSnackBar(context, 'Booking flow for $plan coming soon.');
//                 }),
//                 const SizedBox(height: 28),
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(18),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: const Text(
//                     '“Take a deep breath. Calmness begins the moment you decide to pause.”',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeading(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'AI-powered calm',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           'Experience personalised meditation sessions curated by experts and guided by AI-generated audio.',
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.85),
//             fontSize: 16,
//             height: 1.4,
//           ),
//         ),
//         if (_response?.featured.isNotEmpty ?? false) ...[
//           const SizedBox(height: 24),
//           const Text(
//             'Featured sessions',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 12),
//           SizedBox(
//             height: 170,
//             child: ListView.separated(
//               scrollDirection: Axis.horizontal,
//               itemCount: _response!.featured.length,
//               separatorBuilder: (_, __) => const SizedBox(width: 12),
//               itemBuilder: (context, index) {
//                 final session = _response!.featured[index];
//                 return _FeaturedSessionCard(
//                   session: session,
//                   onTap: () => _openSessionDetails(context, session),
//                 );
//               },
//             ),
//           ),
//         ],
//         const SizedBox(height: 24),
//         const Text(
//           'Select a meditation',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 12),
//       ],
//     );
//   }

//   Widget _buildCategoryWrap(bool isWide, double width) {
//     final categories = ['All', ...?_response?.categories];
//     final cardWidth =
//         isWide ? (width - 80) / 3 : (width - 56) / 2; // replicating layout
//     return Wrap(
//       spacing: 16,
//       runSpacing: 16,
//       children: categories.map((category) {
//         final selected = category == _selectedCategory;
//         return InkWell(
//           onTap: () {
//             setState(() {
//               _selectedCategory = category;
//             });
//           },
//           borderRadius: BorderRadius.circular(18),
//           child: Container(
//             width: cardWidth,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: selected
//                   ? Colors.white.withOpacity(0.28)
//                   : Colors.white.withOpacity(0.18),
//               borderRadius: BorderRadius.circular(18),
//               border: Border.all(
//                 color: selected
//                     ? Colors.white
//                     : Colors.white.withOpacity(0.2),
//               ),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   _iconForCategory(category),
//                   color: Colors.white,
//                   size: 36,
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   category,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   IconData _iconForCategory(String category) {
//     switch (category.toLowerCase()) {
//       case 'sleep':
//         return Icons.nights_stay;
//       case 'focus':
//         return Icons.center_focus_strong;
//       case 'gratitude':
//         return Icons.favorite;
//       case 'breathing':
//         return Icons.air;
//       case 'emotional':
//         return Icons.sentiment_satisfied_alt;
//       default:
//         return Icons.self_improvement;
//     }
//   }

//   void _openSessionDetails(BuildContext context, MeditationSessionItem session) {
//     showModalBottomSheet<void>(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (context) => Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.deepPurple.withOpacity(0.12),
//                   child: Icon(
//                     _iconForCategory(session.category),
//                     color: Colors.deepPurple,
//                     size: 28,
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         session.title,
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.w700,
//                             ),
//                       ),
//                       if (session.subtitle.isNotEmpty)
//                         Text(session.subtitle),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             if (session.description.isNotEmpty)
//               Text(
//                 session.description,
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyMedium
//                     ?.copyWith(height: 1.5),
//               ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Chip(
//                   avatar: const Icon(Icons.timer_outlined, size: 18),
//                   label: Text('${session.durationMinutes} min'),
//                 ),
//                 const SizedBox(width: 8),
//                 Chip(
//                   avatar: const Icon(Icons.flag_outlined, size: 18),
//                   label: Text(session.difficulty),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             FilledButton.icon(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 showSuccessSnackBar(context, 'Playing "${session.title}" (demo preview)…');
//               },
//               icon: const Icon(Icons.play_arrow),
//               label: const Text('Start Session'),
//             ),
//             if (session.audioUrl.isNotEmpty)
//               TextButton.icon(
//                 onPressed: () {
//                   showSuccessSnackBar(context, 'Opening audio URL (demo)…');
//                 },
//                 icon: const Icon(Icons.headphones),
//                 label: const Text('Listen'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _MeditationPageState extends State<MeditationPage> {
  final List<_MeditationCategory> _categories = const [
    _MeditationCategory(
      name: 'Relaxation',
      description: '',
      //     'Relaxation meditation melts stress and invites your body into deep rest.',
      icon: Icons.spa,
    ),
    _MeditationCategory(
      name: 'Sleep',
      description: '',
      // 'Sleep meditation eases you into restful nights and peaceful dreams.',
      icon: Icons.nights_stay,
    ),
    _MeditationCategory(
      name: 'Focus',
      description: '',
      //'Focus meditation helps improve attention and calm.',
      icon: Icons.center_focus_strong,
    ),
    _MeditationCategory(
      name: 'Gratitude',
      description: '',
      //'Gratitude meditation nurtures appreciation and positive emotion.',
      icon: Icons.favorite,
    ),
    // _MeditationCategory(
    //   name: 'Breathing',
    //   description: '',
    //   // 'Breathing meditation guides you through mindful inhales and exhales.',
    //   icon: Icons.air,
    // ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Meditation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D8F97), Color(0xFF6C4CB5), Color(0xFF162A6C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI-Powered Calm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Experience personalized meditation with AI-generated voice and ambient sounds crafted to help you relax wherever you are.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Select a Meditation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _categories
                      .map(
                        (category) => _MeditationCategoryCard(
                          category: category,
                          onTap: () => _showSessionSheet(context, category),
                        ),
                      )
                      .toList(),
                ),
                // const SizedBox(height: 36),
                // const Text(
                //   'Meditation Classes (Paid Sessions)',
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontSize: 22,
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
                // const SizedBox(height: 4),
                // Text(
                //   'Join Meditation Classes',
                //   style: TextStyle(
                //     color: Colors.white.withOpacity(0.85),
                //     fontSize: 16,
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // Text(
                //   'Schedule meditation sessions with certified trainers. Choose from flexible plans and pay per session.',
                //   style: TextStyle(
                //     color: Colors.white.withOpacity(0.85),
                //     fontSize: 15,
                //     height: 1.4,
                //   ),
                // ),
                const SizedBox(height: 20),
                _ClassesSection(onBook: _onBookClass),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '“Take a deep breath. Calmness begins the moment you decide to pause.”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionSheet(BuildContext context, _MeditationCategory category) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              category.description,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startSession(sheetContext, category),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession(BuildContext context, _MeditationCategory category) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Starting ${category.name} session with AI-generated ambient audio...',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onBookClass(String planName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking flow for $planName coming soon!'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _ClassesSection extends StatelessWidget {
  const _ClassesSection({required this.onBook});

  final void Function(String planName) onBook;

  @override
  Widget build(BuildContext context) {
    final classOptions = [
      _ClassOption(
        title: 'One-Day Class',
        description: 'Join a single guided session for quick relaxation.',
        icon: Icons.event_available,
      ),
      _ClassOption(
        title: 'Regular Plan',
        description: 'Create weekly practice with live instructors.',
        icon: Icons.repeat,
      ),
      _ClassOption(
        title: 'Online Video Sessions',
        description: 'Attend virtual meditation classes at your convenience.',
        icon: Icons.videocam,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meditation Classes (paid sessions)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Schedule sessions with certified trainers. Previews below are placeholders.',
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
        const SizedBox(height: 12),
        ...classOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: Icon(option.icon, color: Colors.white, size: 32),
                title: Text(
                  option.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  option.description,
                  style: TextStyle(color: Colors.white.withOpacity(0.85)),
                ),
                trailing: ElevatedButton(
                  onPressed: () => onBook(option.title),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1D8F97),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Book'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClassOption {
  const _ClassOption({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

// -- Helper data types and cards used by this page --

class _MeditationCategory {
  const _MeditationCategory({
    required this.name,
    required this.description,
    required this.icon,
  });

  final String name;
  final String description;
  final IconData icon;
}

class _MeditationCategoryCard extends StatelessWidget {
  const _MeditationCategoryCard({
    required this.category,
    required this.onTap,
  });

  final _MeditationCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple local model used by preview cards in this screen.
class MeditationSessionItem {
  const MeditationSessionItem({
    required this.title,
    this.subtitle = '',
    this.description = '',
    required this.category,
    this.durationMinutes = 10,
    this.difficulty = 'Beginner',
    this.audioUrl = '',
  });

  final String title;
  final String subtitle;
  final String description;
  final String category;
  final int durationMinutes;
  final String difficulty;
  final String audioUrl;
}