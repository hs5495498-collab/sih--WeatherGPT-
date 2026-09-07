import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/languages.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/demo_mode_service.dart';
import '../theme/app_theme.dart';
import 'analytics_dashboard_screen.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Appearance'),
          Consumer<AppSettingsProvider>(
            builder: (context, settings, _) => Column(
              children: ThemeMode.values.map((mode) {
                return RadioListTile<ThemeMode>(
                  value: mode,
                  groupValue: settings.themeMode,
                  onChanged: (m) => m != null ? settings.setThemeMode(m) : null,
                  title: Text(_themeModeLabel(mode)),
                  activeColor: AppColors.gold,
                  dense: true,
                );
              }).toList(),
            ),
          ),

          const Divider(height: 32),
          _SectionHeader('Language & Voice'),
          Consumer2<AppSettingsProvider, ChatProvider>(
            builder: (context, settings, chat, _) => Column(
              children: [
                for (final lang in kSupportedLanguages)
                  RadioListTile<String>(
                    value: lang.code,
                    groupValue: settings.preferredLanguage,
                    activeColor: AppColors.gold,
                    dense: true,
                    title: Text(lang.code == 'en' ? lang.nativeLabel : '${lang.nativeLabel} · ${lang.label}'),
                    subtitle: lang.code == 'en' || !lang.backendResponsesSupported
                        ? null
                        : const Text(
                            'Chat replies are machine-translated from English',
                            style: TextStyle(fontSize: 11),
                          ),
                    onChanged: (code) {
                      if (code == null) return;
                      // Both providers are updated together: AppSettingsProvider
                      // persists it for next launch, ChatProvider applies it to
                      // the live voice session immediately.
                      settings.setPreferredLanguage(code);
                      chat.setLanguage(code);
                    },
                  ),
                const Divider(height: 24, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.speed_rounded, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      const Text('Voice speed', style: TextStyle(fontSize: 14)),
                      const Spacer(),
                      Text('${settings.speechRate.toStringAsFixed(2)}x',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Slider(
                  value: settings.speechRate,
                  min: 0.3,
                  max: 1.0,
                  divisions: 14,
                  activeColor: AppColors.gold,
                  label: '${settings.speechRate.toStringAsFixed(2)}x',
                  onChanged: (rate) {
                    settings.setSpeechRate(rate);
                    chat.setSpeechRate(rate);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => chat.speakVoiceGuidance(),
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: const Text('Play voice guidance sample'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32),
          _SectionHeader('Notifications'),
          Consumer<AppSettingsProvider>(
            builder: (context, settings, _) => SwitchListTile(
              value: settings.notificationsEnabled,
              onChanged: settings.setNotificationsEnabled,
              activeColor: AppColors.gold,
              title: const Text('Severe weather alerts'),
              subtitle: const Text('Get notified about warnings for your area', style: TextStyle(fontSize: 12)),
            ),
          ),

          const Divider(height: 32),
          _SectionHeader('Account'),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.isSupabaseConfigured) {
                return const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Account sign-in not configured'),
                  subtitle: Text('This build runs in guest mode only.', style: TextStyle(fontSize: 12)),
                );
              }
              if (auth.isAuthenticated) {
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded),
                      title: Text(auth.user?.email ?? 'Signed in'),
                      subtitle: const Text('Signed in', style: TextStyle(fontSize: 12)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Sign out'),
                      onTap: () async {
                        await auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                );
              }
              return ListTile(
                leading: const Icon(Icons.login_rounded),
                title: const Text('Sign in'),
                subtitle: const Text('Currently browsing as guest', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              );
            },
          ),

          const Divider(height: 32),
          _SectionHeader('About'),
          const _VersionTile(),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'Follow system';
    }
  }
}

/// Version row that doubles as two hidden dev/demo entry points:
/// - Tapping the leading icon 5 times → PIN prompt → Analytics dashboard.
/// - Tapping the version text 7 times → toggles Demo Mode instantly.
/// Both counters reset after 2 seconds of inactivity so accidental taps
/// spread over time never accumulate into an unintended trigger.
class _VersionTile extends StatefulWidget {
  const _VersionTile();

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  int _iconTaps = 0;
  int _textTaps = 0;
  DateTime? _lastIconTap;
  DateTime? _lastTextTap;

  void _onIconTap() async {
    final now = DateTime.now();
    if (_lastIconTap == null || now.difference(_lastIconTap!) > const Duration(seconds: 2)) {
      _iconTaps = 0;
    }
    _lastIconTap = now;
    _iconTaps++;
    if (_iconTaps >= 5) {
      _iconTaps = 0;
      await _promptForAnalyticsPin();
    }
  }

  void _onTextTap() async {
    final now = DateTime.now();
    if (_lastTextTap == null || now.difference(_lastTextTap!) > const Duration(seconds: 2)) {
      _textTaps = 0;
    }
    _lastTextTap = now;
    _textTaps++;
    if (_textTaps >= 7) {
      _textTaps = 0;
      final demo = DemoModeService.instance;
      await demo.toggle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(demo.enabled ? 'Demo mode ON — sample data everywhere' : 'Demo mode OFF')),
        );
      }
    }
  }

  Future<void> _promptForAnalyticsPin() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          autofocus: true,
          decoration: const InputDecoration(counterText: ''),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok == true && controller.text == '1234' && mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()));
    } else if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? '${snapshot.data!.version} (build ${snapshot.data!.buildNumber})'
            : '—';
        return ListTile(
          leading: GestureDetector(
            onTap: _onIconTap,
            child: const Icon(Icons.info_outline_rounded),
          ),
          title: const Text('Version'),
          subtitle: GestureDetector(
            onTap: _onTextTap,
            child: Text(version, style: const TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
