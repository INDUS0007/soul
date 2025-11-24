import 'package:flutter/material.dart';

import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';

class SupportGroupsPage extends StatefulWidget {
  const SupportGroupsPage({super.key});

  @override
  State<SupportGroupsPage> createState() => _SupportGroupsPageState();
}

class _SupportGroupsPageState extends State<SupportGroupsPage> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  List<SupportGroupItem> _groups = const [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }

    try {
      final groups = await _api.fetchSupportGroups();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
        _refreshing = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
        _refreshing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load support groups. Please try again. ($error)';
        _loading = false;
        _refreshing = false;
      });
    }
  }

  Future<void> _handleRefresh() => _loadGroups(showLoader: false);

  Future<void> _toggleMembership(SupportGroupItem group) async {
    final action =
        group.isJoined ? SupportGroupAction.leave : SupportGroupAction.join;

    try {
      final updated = await _api.updateSupportGroupMembership(
        slug: group.slug,
        action: action,
      );
      if (!mounted) return;
      setState(() {
        _groups = [
          for (final item in _groups)
            if (item.slug == updated.slug) updated else item,
        ];
      });
      showSuccessSnackBar(
        context,
        updated.isJoined
            ? 'Joined ${updated.name}'
            : 'Left ${updated.name}',
      );
    } on ApiClientException catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, error.message);
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Unable to update membership. Please try again. ($error)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Groups'),
        backgroundColor: const Color(0xFF8B5FBF),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFDFBFF),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && !_refreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadGroups,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Join safe, supportive communities to share and grow together.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF1A1B41),
            ),
          ),
          const SizedBox(height: 20),
          ..._groups.map(_buildGroupCard),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              'You are never alone — someone understands what you feel.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: Color(0xFF6B6B8E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(SupportGroupItem group) {
    IconData icon;
    switch (group.icon) {
      case 'work_outline_rounded':
        icon = Icons.work_outline_rounded;
        break;
      case 'favorite_outline_rounded':
        icon = Icons.favorite_outline_rounded;
        break;
      case 'self_improvement_rounded':
        icon = Icons.self_improvement_rounded;
        break;
      case 'people_alt_rounded':
      default:
        icon = Icons.people_alt_rounded;
        break;
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _toggleMembership(group),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5FBF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF8B5FBF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1B41),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF6B6B8E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: group.isJoined
                      ? const Color(0xFF8B5FBF)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  group.isJoined ? 'Joined' : 'Join',
                  style: TextStyle(
                    color: group.isJoined ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


