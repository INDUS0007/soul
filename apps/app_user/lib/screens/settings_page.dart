import 'package:flutter/material.dart';

import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';
import 'login_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  bool _updating = false;
  String? _error;
  UserSettings? _settings;

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
      final data = await _api.fetchUserSettings();
      if (!mounted) return;
      setState(() {
        _settings = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load settings. $error';
      });
    }
  }

  Future<void> _updateSettings({
    bool? notificationsEnabled,
    bool? prefersDarkMode,
    String? language,
  }) async {
    if (_settings == null) return;
    final previous = _settings!;
    final updated = previous.copyWith(
      notificationsEnabled: notificationsEnabled,
      prefersDarkMode: prefersDarkMode,
      language: language,
    );
    setState(() {
      _settings = updated;
      _updating = true;
    });

    try {
      final result = await _api.updateUserSettings(
        notificationsEnabled: updated.notificationsEnabled,
        prefersDarkMode: updated.prefersDarkMode,
        language: updated.language,
      );
      if (!mounted) return;
      setState(() {
        _settings = result;
        _updating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _settings = previous;
        _updating = false;
      });
      showErrorSnackBar(context, 'Update failed: $error');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(color: Colors.black87)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _api.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openAccountBottomSheet() {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account details',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              _AccountDetailRow(label: 'Name', value: settings.fullName ?? 'Not set'),
              _AccountDetailRow(label: 'Nickname', value: settings.nickname ?? 'Not set'),
              _AccountDetailRow(label: 'Phone', value: settings.phone ?? 'Not set'),
              _AccountDetailRow(
                label: 'Age',
                value: settings.age != null ? settings.age.toString() : 'Not set',
              ),
              _AccountDetailRow(label: 'Gender', value: settings.gender ?? 'Not set'),
              const SizedBox(height: 12),
              Text(
                'To update these details, visit the profile section on the dashboard.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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

    final settings = _settings!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: primary,
        actions: [
          if (_updating)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFFDFBFF),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _SettingsCard(
            child: ListTile(
              leading: Icon(Icons.person_outline, color: primary),
              title: const Text(
                'Account',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Manage your account details',
                style: TextStyle(color: Colors.black54),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.black54),
              onTap: _openAccountBottomSheet,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: SwitchListTile(
              value: settings.notificationsEnabled,
              activeColor: primary,
              title: const Text(
                'Notifications',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Receive updates and reminders',
                  style: TextStyle(color: Colors.black54)),
              onChanged: (value) => _updateSettings(notificationsEnabled: value),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: SwitchListTile(
              value: settings.prefersDarkMode,
              activeColor: primary,
              title: const Text(
                'Use dark mode',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Reduce eye strain and save battery',
                style: TextStyle(color: Colors.black54),
              ),
              onChanged: (value) => _updateSettings(prefersDarkMode: value),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              leading: Icon(Icons.language, color: primary),
              title: const Text(
                'Language',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(settings.language, style: const TextStyle(color: Colors.black54)),
              trailing: const Icon(Icons.chevron_right, color: Colors.black54),
              onTap: () async {
                final selection = await showModalBottomSheet<String>(
                  context: context,
                  builder: (context) => _LanguageSelector(current: settings.language),
                );
                if (selection != null && selection != settings.language) {
                  _updateSettings(language: selection);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              leading: Icon(Icons.lock_outline, color: primary),
              title: const Text(
                'Privacy & Security',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Manage permissions and data',
                  style: TextStyle(color: Colors.black54)),
              trailing: const Icon(Icons.chevron_right, color: Colors.black54),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _InfoPage(
                    title: 'Privacy & Security',
                    message:
                        'Your privacy matters to us. All personal data is stored securely and used only to improve your wellness experience.',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: primary),
              title: const Text(
                'About',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('App version and legal info',
                  style: TextStyle(color: Colors.black54)),
              trailing: const Icon(Icons.chevron_right, color: Colors.black54),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _InfoPage(
                    title: 'About Soul Support',
                    message:
                        'Soul Support is your companion for mindful living, combining personalised routines, expert guidance, and community support.',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              leading: Icon(Icons.rule, color: primary),
              title: const Text(
                'Terms & Conditions',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.black54),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _InfoPage(
                    title: 'Terms & Conditions',
                    message:
                        'By using Soul Support you agree to our community guidelines and consent to receive wellbeing-related updates.',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            child: ListTile(
              leading: Icon(Icons.support_agent, color: primary),
              title: const Text(
                'Contact & Feedback',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.black54),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _InfoPage(
                    title: 'Contact & Feedback',
                    message:
                        'We would love to hear from you. Drop us a message at support@soulsupport.example for feedback or assistance.',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _logout,
              child: const Text('Logout'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: child,
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final languages = ['English', 'తెలుగు', 'हिंदी'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: languages
            .map(
              (lang) => ListTile(
                title: Text(lang, style: const TextStyle(color: Colors.black87)),
                trailing: current == lang ? const Icon(Icons.check, color: Colors.teal) : null,
                onTap: () => Navigator.pop(context, lang),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AccountDetailRow extends StatelessWidget {
  const _AccountDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF8B5FBF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}

