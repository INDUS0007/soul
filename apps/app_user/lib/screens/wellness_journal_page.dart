import 'package:flutter/material.dart';
import 'package:common/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessJournalPage extends StatelessWidget {
  const WellnessJournalPage({super.key});

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Publications'),
      backgroundColor: const Color(0xFF4DB6AC),
      elevation: 0,
    ),
    body: const _PublicationsTab(),
  );
}

}

class _PublicationsTab extends StatefulWidget {
  const _PublicationsTab({super.key});

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

      final list = (resp.resources as List<dynamic>).map<GuidanceResourceItem>((e) {
        if (e is GuidanceResourceItem) return e;
        if (e is Map<String, dynamic>) return GuidanceResourceItem.fromJson(e);
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

      final hasSoul = list.any((e) => e.title.toLowerCase().contains('soul'));

      if (!hasSoul) {
        list.insert(
          0,
          GuidanceResourceItem(
            id: -9999,
            type: 'article',
            title: 'Soul Support: Ongoing Help & Resources',
            subtitle: 'Practical support, updated regularly',
            summary:
                'Soul Support is our ongoing initiative offering short articles, exercises and contact points to help you through stressful moments. We update this collection regularly with new guidance and community resources.',
            category: 'support',
            duration: '',
            mediaUrl: '',
            thumbnail:
                'https://via.placeholder.com/400x240.png?text=Soul+Support',
            isFeatured: true,
          ),
        );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PublicationDetailPage(resource: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadItems,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const Text(
              'Recently updated publications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse the latest journal articles and resources published by our experts.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search publications',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (v) => setState(() => _filter = v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'recent', child: Text('Recent')),
                    PopupMenuItem(value: 'featured', child: Text('Featured')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator()),
            ] else if (_error != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Failed to load: $_error'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadItems,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final resource = _filteredItems[index];
                  final title = (resource.title ?? '').toString();
                  final subtitle =
                      (resource.subtitle ?? resource.summary ?? '').toString();
                  final thumb = (resource.thumbnail ?? '').toString();

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () => _openDetail(resource),
                      leading: thumb.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                thumb,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.article),
                              ),
                            )
                          : const Icon(
                              Icons.article,
                              size: 44,
                              color: Colors.grey,
                            ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PublicationDetailPage extends StatelessWidget {
  final GuidanceResourceItem resource;

  const _PublicationDetailPage({super.key, required this.resource});

  @override
  Widget build(BuildContext context) {
    final title = resource.title.toString();
    final summary = (resource.summary.isNotEmpty
            ? resource.summary
            : resource.subtitle)
        .toString();
    final media = resource.mediaUrl.toString();
    final thumbnail = resource.thumbnail.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF8B5FBF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  thumbnail,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              summary,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            if (media.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final uri = Uri.tryParse(media);
                    if (uri == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid media URL')),
                      );
                      return;
                    }

                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to open media')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unable to open media: $e'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('Open Media'),
              ),
          ],
        ),
      ),
    );
  }
}