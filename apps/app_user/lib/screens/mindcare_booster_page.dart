// import 'package:flutter/material.dart';

// import 'package:common/api/api_client.dart';
// import 'package:common/common.dart';
// import 'package:common/widgets/widgets.dart';

// class MindCareBoosterPage extends StatefulWidget {
//   const MindCareBoosterPage({super.key});

//   @override
//   State<MindCareBoosterPage> createState() => _MindCareBoosterPageState();
// }

// class _MindCareBoosterPageState extends State<MindCareBoosterPage> {
//   final ApiClient _api = ApiClient();

//   bool _loading = true;
//   String? _error;
//   MindCareBoostersResponse? _response;
//   String _selectedCategory = 'All';

//   @override
//   void initState() {
//     super.initState();
//     _loadBoosters();
//   }

//   Future<void> _loadBoosters({String? category}) async {
//     setState(() {
//       _loading = true;
//       _error = null;
//       if (category != null) {
//         _selectedCategory = category;
//       }
//     });
//     try {
//       final response = await _api.fetchMindCareBoosters(
//         category: _selectedCategory == 'All' ? null : _selectedCategory,
//       );
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
//         _error = 'Unable to load boosters at the moment.';
//         _loading = false;
//       });
//     }
//   }

//   List<MindCareBoosterItem> get _visibleBoosters {
//     final response = _response;
//     if (response == null) return const [];
//     if (_selectedCategory == 'All') {
//       return response.boosters;
//     }
//     return response.groupedByCategory[_selectedCategory] ?? const [];
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('MindCare Booster'),
//         backgroundColor: colorScheme.primary,
//         foregroundColor: colorScheme.onPrimary,
//       ),
//       body: RefreshIndicator(
//         onRefresh: () => _loadBoosters(category: _selectedCategory),
//         child: ListView(
//           padding: const EdgeInsets.all(24),
//           children: [
//             _buildHeroCard(colorScheme),
//             const SizedBox(height: 24),
//             _buildHowItWorksCard(colorScheme),
//             const SizedBox(height: 24),
//             if (_response?.categories.isNotEmpty ?? false)
//               _CategorySelector(
//                 categories: ['All', ...?_response?.categories],
//                 selected: _selectedCategory,
//                 onSelected: (value) => _loadBoosters(category: value),
//               ),
//             if (_loading) ...[
//               const SizedBox(height: 48),
//               const Center(child: CircularProgressIndicator()),
//             ] else if (_error != null) ...[
//               const SizedBox(height: 32),
//               ErrorMessage(message: _error!, onRetry: () => _loadBoosters()),
//             ] else if (_visibleBoosters.isEmpty) ...[
//               const SizedBox(height: 48),
//               const _EmptyMessage(message: 'No boosters available for now.'),
//             ] else ...[
//               _buildBoosterGrid(context, _visibleBoosters),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeroCard(ColorScheme colorScheme) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       color: colorScheme.primary,
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const Icon(Icons.bolt, size: 60, color: Colors.white),
//             const SizedBox(height: 12),
//             const Text(
//               'Instant Wellness Boost',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Short, science-backed exercises to reset your mind in under two minutes.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.white.withOpacity(0.82),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHowItWorksCard(ColorScheme colorScheme) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       color: colorScheme.secondaryContainer,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Text(
//               'How it works',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: colorScheme.onSecondaryContainer,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Pick a booster that fits your moment. Each activity includes prompts or resources assembled by our therapists.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 15,
//                 color: colorScheme.onSecondaryContainer.withOpacity(0.8),
//                 height: 1.5,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBoosterGrid(
//     BuildContext context,
//     List<MindCareBoosterItem> boosters,
//   ) {
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         mainAxisSpacing: 16,
//         crossAxisSpacing: 16,
//         childAspectRatio: 0.78,
//       ),
//       itemCount: boosters.length,
//       itemBuilder: (context, index) {
//         final booster = boosters[index];
//         final iconData = _iconForBooster(booster.icon, booster.category);
//         return _BoosterTile(
//           icon: iconData,
//           booster: booster,
//           onTap: () => _showBoosterDetails(context, booster, iconData),
//         );
//       },
//     );
//   }

//   void _showBoosterDetails(
//     BuildContext context,
//     MindCareBoosterItem booster,
//     IconData icon,
//   ) {
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
//                   radius: 28,
//                   child: Icon(icon, size: 28),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         booster.title,
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.w600,
//                             ),
//                       ),
//                       if (booster.subtitle.isNotEmpty)
//                         Text(
//                           booster.subtitle,
//                           style: Theme.of(context).textTheme.bodyMedium,
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             if (booster.description.isNotEmpty)
//               Text(
//                 booster.description,
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyMedium
//                     ?.copyWith(height: 1.5),
//               ),
//             if (booster.prompt.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               Text(
//                 'Try this:',
//                 style: Theme.of(context).textTheme.titleMedium,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 booster.prompt,
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyMedium
//                     ?.copyWith(height: 1.5),
//               ),
//             ],
//             const SizedBox(height: 16),
//             Text(
//               'Estimated time: ${booster.estimatedSeconds ~/ 60} min ${(booster.estimatedSeconds % 60).toString().padLeft(2, '0')} sec',
//               style: Theme.of(context).textTheme.bodySmall,
//             ),
//             if (booster.resourceUrl.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               TextButton.icon(
//                 onPressed: () {
//                   showSuccessSnackBar(context, 'Launching resource (demo)…');
//                 },
//                 icon: const Icon(Icons.open_in_new),
//                 label: Text(booster.actionLabel),
//               ),
//             ] else ...[
//               const SizedBox(height: 16),
//               FilledButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   showSuccessSnackBar(context, '${booster.actionLabel} (demo)…');
//                 },
//                 child: Text(booster.actionLabel),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   IconData _iconForBooster(String icon, String category) {
//     switch (icon) {
//       case 'self_improvement':
//         return Icons.self_improvement;
//       case 'favorite':
//         return Icons.favorite;
//       case 'accessibility_new':
//         return Icons.accessibility_new;
//       case 'music_note':
//         return Icons.music_note;
//     }

//     switch (category) {
//       case 'breathing':
//         return Icons.self_improvement;
//       case 'movement':
//         return Icons.accessibility_new;
//       case 'reflection':
//         return Icons.bubble_chart_outlined;
//       case 'audio':
//         return Icons.music_note;
//       default:
//         return Icons.bolt;
//     }
//   }
// }

// class _CategorySelector extends StatelessWidget {
//   const _CategorySelector({
//     required this.categories,
//     required this.selected,
//     required this.onSelected,
//   });

//   final List<String> categories;
//   final String selected;
//   final ValueChanged<String> onSelected;

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: categories.map((category) {
//         final isSelected = category == selected;
//         return ChoiceChip(
//           label: Text(category),
//           selected: isSelected,
//           onSelected: (_) => onSelected(category),
//         );
//       }).toList(),
//     );
//   }
// }

// class _BoosterTile extends StatelessWidget {
//   const _BoosterTile({
//     required this.icon,
//     required this.booster,
//     required this.onTap,
//   });

//   final IconData icon;
//   final MindCareBoosterItem booster;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;
//     return InkWell(
//       borderRadius: BorderRadius.circular(16),
//       onTap: onTap,
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               CircleAvatar(
//                 radius: 28,
//                 backgroundColor: colorScheme.primary.withOpacity(0.12),
//                 child: Icon(icon, color: colorScheme.primary, size: 28),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 booster.title,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//               ),
//               if (booster.subtitle.isNotEmpty) ...[
//                 const SizedBox(height: 6),
//                 Text(
//                   booster.subtitle,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(color: colorScheme.onSurfaceVariant),
//                 ),
//               ],
//               const Spacer(),
//               Text(
//                 booster.actionLabel,
//                 style: TextStyle(
//                   color: colorScheme.primary,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Removed duplicate _ErrorMessage class - use ErrorMessage from common package

// class _EmptyMessage extends StatelessWidget {
//   const _EmptyMessage({required this.message});

//   final String message;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
//         const SizedBox(height: 12),
//         Text(
//           message,
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }
// }




import 'dart:math';

import 'package:flutter/material.dart';

import 'package:common/api/api_client.dart';
import 'package:common/common.dart';
import 'package:common/widgets/widgets.dart';

class MindCareBoosterPage extends StatefulWidget {
  const MindCareBoosterPage({super.key});

  @override
  State<MindCareBoosterPage> createState() => _MindCareBoosterPageState();
}

class _MindCareBoosterPageState extends State<MindCareBoosterPage> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  String? _error;
  MindCareBoostersResponse? _response;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadBoosters();
  }

  Future<void> _loadBoosters({String? category}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (category != null) {
        _selectedCategory = category;
      }
    });
    try {
      final response = await _api.fetchMindCareBoosters(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _response = response;
        _loading = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load boosters at the moment.';
        _loading = false;
      });
    }
  }

  List<MindCareBoosterItem> get _visibleBoosters {
    final response = _response;
    if (response == null) return const [];
    if (_selectedCategory == 'All') {
      return response.boosters;
    }
    return response.groupedByCategory[_selectedCategory] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindCare Booster'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadBoosters(category: _selectedCategory),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildHeroCard(colorScheme),
            const SizedBox(height: 24),
            _buildHowItWorksCard(colorScheme),
            const SizedBox(height: 16),
            // Puzzle booster: quick word-scramble to engage attention
            const _PuzzleBoosterCard(),
            const SizedBox(height: 16),
            // Puzzle booster: missing letters activity
            const _MissingLettersCard(),
            const SizedBox(height: 24),
            if (_response?.categories.isNotEmpty ?? false)
              _CategorySelector(
                categories: ['All', ...?_response?.categories],
                selected: _selectedCategory,
                onSelected: (value) => _loadBoosters(category: value),
              ),
            if (_loading) ...[
              const SizedBox(height: 48),
              const Center(child: CircularProgressIndicator()),
            ] else if (_error != null) ...[
              const SizedBox(height: 32),
              ErrorMessage(message: _error!, onRetry: () => _loadBoosters()),
            ] else if (_visibleBoosters.isEmpty) ...[
              const SizedBox(height: 48),
              const _EmptyMessage(message: 'No boosters available for now.'),
            ] else ...[
              _buildBoosterGrid(context, _visibleBoosters),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, size: 60, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              'Instant Wellness Boost',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Short, science-backed exercises to reset your mind in under two minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard(ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'How it works',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pick a booster that fits your moment. Each activity includes prompts or resources assembled by our therapists.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSecondaryContainer.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoosterGrid(
    BuildContext context,
    List<MindCareBoosterItem> boosters,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: boosters.length,
      itemBuilder: (context, index) {
        final booster = boosters[index];
        final iconData = _iconForBooster(booster.icon, booster.category);
        return _BoosterTile(
          icon: iconData,
          booster: booster,
          onTap: () => _showBoosterDetails(context, booster, iconData),
        );
      },
    );
  }

  void _showBoosterDetails(
    BuildContext context,
    MindCareBoosterItem booster,
    IconData icon,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Icon(icon, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booster.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (booster.subtitle.isNotEmpty)
                        Text(
                          booster.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (booster.description.isNotEmpty)
              Text(
                booster.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ),
            if (booster.prompt.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Try this:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                booster.prompt,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Estimated time: ${booster.estimatedSeconds ~/ 60} min ${(booster.estimatedSeconds % 60).toString().padLeft(2, '0')} sec',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (booster.resourceUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  showSuccessSnackBar(context, 'Launching resource (demo)…');
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(booster.actionLabel),
              ),
            ] else ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  showSuccessSnackBar(context, '${booster.actionLabel} (demo)…');
                },
                child: Text(booster.actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForBooster(String icon, String category) {
    switch (icon) {
      case 'self_improvement':
        return Icons.self_improvement;
      case 'favorite':
        return Icons.favorite;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'music_note':
        return Icons.music_note;
    }

    switch (category) {
      case 'breathing':
        return Icons.self_improvement;
      case 'movement':
        return Icons.accessibility_new;
      case 'reflection':
        return Icons.bubble_chart_outlined;
      case 'audio':
        return Icons.music_note;
      default:
        return Icons.bolt;
    }
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = category == selected;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) => onSelected(category),
        );
      }).toList(),
    );
  }
}

class _BoosterTile extends StatelessWidget {
  const _BoosterTile({
    required this.icon,
    required this.booster,
    required this.onTap,
  });

  final IconData icon;
  final MindCareBoosterItem booster;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary.withOpacity(0.12),
                child: Icon(icon, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                booster.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (booster.subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  booster.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
              const Spacer(),
              Text(
                booster.actionLabel,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed duplicate _ErrorMessage class - use ErrorMessage from common package

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PuzzleBoosterCard extends StatefulWidget {
  const _PuzzleBoosterCard();

  @override
  State<_PuzzleBoosterCard> createState() => _PuzzleBoosterCardState();
}

class _MissingLettersCard extends StatefulWidget {
  const _MissingLettersCard();

  @override
  State<_MissingLettersCard> createState() => _MissingLettersCardState();
}

class _MissingLettersCardState extends State<_MissingLettersCard> {
  final List<String> _words = ['breathe', 'calm', 'pause', 'gentle', 'focus', 'smile', 'ground', 'listen', 'center'];
  late String _word;
  late String _masked;
  final TextEditingController _controller = TextEditingController();
  String? _message;

  @override
  void initState() {
    super.initState();
    _pickNew();
  }

  void _pickNew() {
    final rnd = Random();
    _word = _words[rnd.nextInt(_words.length)];
    _masked = _maskWord(_word, rnd);
    _controller.clear();
    _message = null;
    setState(() {});
  }

  String _maskWord(String w, Random rnd) {
    if (w.length <= 3) return w.replaceAll(RegExp(r'.'), '_');
    final chars = w.split('');
    // mask ~40% of letters (at least 1)
    final toMask = (chars.length * 0.4).ceil().clamp(1, chars.length - 1);
    final indices = List<int>.generate(chars.length, (i) => i);
    indices.shuffle(rnd);
    final maskSet = indices.take(toMask).toSet();
    final out = <String>[];
    for (var i = 0; i < chars.length; i++) {
      out.add(maskSet.contains(i) ? '_' : chars[i]);
    }
    return out.join(' ');
  }

  void _checkAnswer() {
    final attempt = _controller.text.trim().toLowerCase();
    if (attempt.isEmpty) {
      setState(() => _message = 'Please fill the missing letters');
      return;
    }
    if (attempt == _word.toLowerCase()) {
      showSuccessSnackBar(context, 'Great — you completed "$_word"');
      setState(() => _message = 'Correct — well done!');
    } else {
      setState(() => _message = 'Not quite — try again');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.create), const SizedBox(width: 12), Text('Puzzle: Missing Letters', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))]),
            const SizedBox(height: 12),
            Text('Fill in the missing letters to complete the calming word:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _masked.toUpperCase(),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _controller, textCapitalization: TextCapitalization.none, decoration: const InputDecoration(labelText: 'Complete word', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [FilledButton(onPressed: _checkAnswer, child: const Text('Check')), const SizedBox(width: 8), OutlinedButton(onPressed: _pickNew, child: const Text('New')), const SizedBox(width: 8), TextButton(onPressed: () => setState(() => _controller.text = _word), child: const Text('Reveal'))]),
            if (_message != null) ...[const SizedBox(height: 8), Text(_message!, style: TextStyle(color: _message!.startsWith('Correct') || _message == 'Correct — well done!' ? Colors.green : Colors.orange))],
          ],
        ),
      ),
    );
  }
}

class _PuzzleBoosterCardState extends State<_PuzzleBoosterCard> {
  final List<String> _words = ['breathe', 'calm', 'pause', 'gentle', 'focus', 'smile', 'ground'];
  late String _word;
  late String _scrambled;
  final TextEditingController _controller = TextEditingController();
  String? _message;

  @override
  void initState() {
    super.initState();
    _pickNew();
  }

  void _pickNew() {
    final rnd = Random();
    _word = _words[rnd.nextInt(_words.length)];
    _scrambled = _shuffle(_word, rnd);
    if (_scrambled == _word) {
      _scrambled = _shuffle(_word + 'x', rnd).replaceAll('x', '');
    }
    _controller.clear();
    _message = null;
    setState(() {});
  }

  String _shuffle(String s, Random rnd) {
    final chars = s.split('');
    for (var i = chars.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }
    return chars.join();
  }

  void _checkAnswer() {
    final attempt = _controller.text.trim().toLowerCase();
    if (attempt.isEmpty) {
      setState(() => _message = 'Try entering the word above');
      return;
    }
    if (attempt == _word.toLowerCase()) {
      showSuccessSnackBar(context, 'Nice! You solved it — $_word');
      setState(() => _message = 'Correct — well done!');
    } else {
      setState(() => _message = 'Not quite — try again');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.extension), const SizedBox(width: 12), Text('Puzzle: Unscramble', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))]),
            const SizedBox(height: 12),
            Text('Unscramble the letters to form a calming word:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _scrambled.toUpperCase(),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _controller, textCapitalization: TextCapitalization.none, decoration: const InputDecoration(labelText: 'Your answer', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [FilledButton(onPressed: _checkAnswer, child: const Text('Check')), const SizedBox(width: 8), OutlinedButton(onPressed: _pickNew, child: const Text('Shuffle')), const SizedBox(width: 8), TextButton(onPressed: () => setState(() => _controller.text = _word), child: const Text('Reveal'))]),
            if (_message != null) ...[const SizedBox(height: 8), Text(_message!, style: TextStyle(color: _message!.startsWith('Correct') || _message == 'Correct — well done!' ? Colors.green : Colors.orange))],
          ],
        ),
      ),
    );
  }
}