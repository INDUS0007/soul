import 'package:flutter/material.dart';

import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  String? _error;
  MusicTracksResponse? _response;
  String? _selectedMood;
  String? _playingTrackId;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks({String? mood}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (mood != null) {
        _selectedMood = mood.isEmpty ? null : mood;
      }
    });
    try {
      final response = await _api.fetchMusicTracks(mood: _selectedMood);
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong while loading music tracks.';
        _loading = false;
      });
    }
  }

  void _toggleTrack(MusicTrackItem track) {
    setState(() {
      if (_playingTrackId == track.id.toString()) {
        _playingTrackId = null;
        showSuccessSnackBar(context, 'Paused "${track.title}"');
      } else {
        _playingTrackId = track.id.toString();
        showSuccessSnackBar(context, 'Playing "${track.title}" (demo preview)');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tracks = _response?.tracks ?? const <MusicTrackItem>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calm Music'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadTracks(mood: _selectedMood ?? ''),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(colorScheme),
            const SizedBox(height: 16),
            if (_response?.moods.isNotEmpty ?? false) _buildMoodSelector(colorScheme),
            if (_loading) ...[
              const SizedBox(height: 32),
              const Center(child: CircularProgressIndicator()),
            ] else if (_error != null) ...[
              const SizedBox(height: 32),
              _ErrorState(
                message: _error!,
                onRetry: () => _loadTracks(mood: _selectedMood ?? ''),
              ),
            ] else if (tracks.isEmpty) ...[
              const SizedBox(height: 32),
              const _EmptyState(message: 'No tracks available right now.'),
            ] else ...[
              ...tracks.map((track) => _MusicTrackTile(
                    track: track,
                    playingId: _playingTrackId,
                    onToggle: _toggleTrack,
                  )),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: tracks.isEmpty
                    ? null
                    : () => _toggleTrack(tracks.first),
                icon: const Icon(Icons.playlist_play),
                label: const Text('Play All (demo)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.music_note, color: colorScheme.primary, size: 36),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Relax instantly with curated ambient tracks streamed from the Soul Support library.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector(ColorScheme colorScheme) {
    final moods = ['All', ...?_response?.moods];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: moods.map((mood) {
        final bool selected =
            (_selectedMood == null && mood == 'All') || _selectedMood == mood;
        return ChoiceChip(
          label: Text(mood),
          selected: selected,
          onSelected: (value) {
            if (!value) return;
            _loadTracks(mood: mood == 'All' ? '' : mood);
          },
          selectedColor: colorScheme.primary,
          labelStyle: TextStyle(
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        );
      }).toList(),
    );
  }
}

class _MusicTrackTile extends StatelessWidget {
  const _MusicTrackTile({
    required this.track,
    required this.playingId,
    required this.onToggle,
  });

  final MusicTrackItem track;
  final String? playingId;
  final void Function(MusicTrackItem track) onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPlaying = playingId == track.id.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(
          isPlaying ? Icons.equalizer : Icons.library_music,
          color: colorScheme.primary,
        ),
        title: Text(
          track.title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (track.durationFormatted.isNotEmpty) track.durationFormatted,
            if (track.mood.isNotEmpty) track.mood.toUpperCase(),
          ].join(' • '),
        ),
        trailing: IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            size: 32,
            color: colorScheme.primary,
          ),
          onPressed: () => onToggle(track),
        ),
        onTap: () => onToggle(track),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.queue_music, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

