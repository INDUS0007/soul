import 'package:flutter/material.dart';

import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';

class ProfessionalGuidancePage extends StatefulWidget {
  const ProfessionalGuidancePage({super.key});

  @override
  State<ProfessionalGuidancePage> createState() => _ProfessionalGuidancePageState();
}

class _ProfessionalGuidancePageState extends State<ProfessionalGuidancePage> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  String? _error;
  GuidanceResponse? _response;

  String _selectedType = 'all';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _api.fetchGuidanceResources(
        type: _selectedType == 'all' ? null : _selectedType,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _response = resp;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load guidance content. $error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Professional Guidance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF8B5FBF),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Professional Guidance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF8B5FBF),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final response = _response!;
    final categories = ['All', ...response.categories];

    final typeChips = {
      'all': 'All',
      'article': 'Articles',
      'talk': 'Expert Talks',
      'podcast': 'Podcasts',
    };

    final resources = response.resources;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Professional Guidance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5FBF),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
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
            child: const Text(
              'Expert-curated insights, videos, and podcasts — explore the topics that matter to you.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          Container(
            height: 50,
            margin: const EdgeInsets.only(top: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: typeChips.entries.map((entry) {
                final selected = _selectedType == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedType = entry.key);
                      _load();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF8B5FBF).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selected
                          ? const Color(0xFF8B5FBF)
                          : Colors.grey[700],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF8B5FBF)
                            : Colors.grey[300]!,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            height: 44,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                borderRadius: BorderRadius.circular(16),
                items: categories
                    .map(
                      (cat) => DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCategory = value);
                  _load();
                },
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: resources.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'No resources found for the selected filters.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: resources.length,
                      itemBuilder: (context, index) {
                        final resource = resources[index];
                        switch (resource.type) {
                          case 'talk':
                            return _ExpertTalkCard(resource: resource);
                          case 'podcast':
                            return _PodcastCard(resource: resource);
                          default:
                            return _ArticleCard(resource: resource);
                        }
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.resource});

  final GuidanceResourceItem resource;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            Text(
              resource.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              resource.subtitle.isEmpty ? 'Soul Support Team' : resource.subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            Text(
              resource.summary.isEmpty
                  ? 'Stay tuned for detailed guidance tailored for your journey.'
                  : resource.summary,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  resource.duration.isEmpty ? '5 min read' : resource.duration,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                TextButton(
                  onPressed: () {
                    showSuccessSnackBar(context, 'Article viewer coming soon!');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5FBF),
                  ),
                  child: const Text('Read More'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpertTalkCard extends StatelessWidget {
  const _ExpertTalkCard({required this.resource});

  final GuidanceResourceItem resource;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5FBF).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 50,
                color: Color(0xFF8B5FBF),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resource.subtitle.isEmpty ? 'Expert speaker' : resource.subtitle,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      resource.duration.isEmpty ? '20 min' : resource.duration,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  resource.summary.isEmpty
                      ? 'Watch this expert session for actionable strategies.'
                      : resource.summary,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodcastCard extends StatelessWidget {
  const _PodcastCard({required this.resource});

  final GuidanceResourceItem resource;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5FBF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.headphones,
                color: Color(0xFF8B5FBF),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.subtitle.isEmpty ? 'Soul Support Podcast' : resource.subtitle,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.duration.isEmpty ? '30 min' : resource.duration,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              color: const Color(0xFF8B5FBF),
              iconSize: 36,
              onPressed: () {
                showSuccessSnackBar(context, 'Podcast player coming soon!');
              },
            ),
          ],
        ),
      ),
    );
  }
}

