import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight, on-device usage counters shown on the hidden Analytics
/// screen (Settings → tap the Version row's icon 5 times → PIN 1234).
///
/// Honest scope note: this is a LOCAL counter, not a real analytics
/// pipeline. It counts what has happened on *this* phone since install —
/// there is no backend table aggregating events across users, and no
/// "daily active users" figure, because that would require a server-side
/// events endpoint plus a way to distinguish devices/users, neither of
/// which exists yet. Faking a company-wide number here would be worse
/// than not showing one. What's shown is real and locally verifiable:
/// this device's own message count, language usage, SOS test runs, and
/// advisory views.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const _kChatMessages = 'analytics_chat_messages_total';
  static const _kSosTests = 'analytics_sos_tests_total';
  static const _kAdvisoryViewsPrefix = 'analytics_advisory_views_'; // + domain
  static const _kLanguageUsagePrefix = 'analytics_lang_usage_'; // + code
  static const _kAppOpens = 'analytics_app_opens_total';
  static const _kFirstLaunch = 'analytics_first_launch_iso';

  Future<void> _increment(String key, {int by = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + by);
  }

  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kFirstLaunch)) {
      await prefs.setString(_kFirstLaunch, DateTime.now().toIso8601String());
    }
    await _increment(_kAppOpens);
  }

  Future<void> recordChatMessageSent({required String languageCode}) async {
    await _increment(_kChatMessages);
    await _increment('$_kLanguageUsagePrefix$languageCode');
  }

  Future<void> recordSosTestTriggered() => _increment(_kSosTests);

  Future<void> recordAdvisoryViewed(String domain) => _increment('$_kAdvisoryViewsPrefix$domain');

  /// Snapshot of everything currently stored, read fresh each time the
  /// hidden dashboard opens (deliberately not cached in memory — it's
  /// cheap and this way the numbers are never stale).
  Future<AnalyticsSnapshot> snapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final languageUsage = <String, int>{};
    final advisoryViews = <String, int>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_kLanguageUsagePrefix)) {
        final code = key.substring(_kLanguageUsagePrefix.length);
        languageUsage[code] = prefs.getInt(key) ?? 0;
      } else if (key.startsWith(_kAdvisoryViewsPrefix)) {
        final domain = key.substring(_kAdvisoryViewsPrefix.length);
        advisoryViews[domain] = prefs.getInt(key) ?? 0;
      }
    }
    DateTime? firstLaunch;
    final firstLaunchIso = prefs.getString(_kFirstLaunch);
    if (firstLaunchIso != null) {
      firstLaunch = DateTime.tryParse(firstLaunchIso);
    }
    return AnalyticsSnapshot(
      chatMessagesTotal: prefs.getInt(_kChatMessages) ?? 0,
      sosTestsTotal: prefs.getInt(_kSosTests) ?? 0,
      appOpensTotal: prefs.getInt(_kAppOpens) ?? 0,
      firstLaunch: firstLaunch,
      languageUsage: languageUsage,
      advisoryViews: advisoryViews,
    );
  }

  /// Wipes all locally stored counters. Exposed for the demo/reset flow —
  /// useful right before a real demo so numbers aren't confused with dev
  /// testing traffic.
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (key == _kChatMessages ||
          key == _kSosTests ||
          key == _kAppOpens ||
          key == _kFirstLaunch ||
          key.startsWith(_kLanguageUsagePrefix) ||
          key.startsWith(_kAdvisoryViewsPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.chatMessagesTotal,
    required this.sosTestsTotal,
    required this.appOpensTotal,
    required this.firstLaunch,
    required this.languageUsage,
    required this.advisoryViews,
  });

  final int chatMessagesTotal;
  final int sosTestsTotal;
  final int appOpensTotal;
  final DateTime? firstLaunch;
  final Map<String, int> languageUsage; // code -> count
  final Map<String, int> advisoryViews; // domain -> count

  String get mostUsedLanguage {
    if (languageUsage.isEmpty) return '—';
    final sorted = languageUsage.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}
