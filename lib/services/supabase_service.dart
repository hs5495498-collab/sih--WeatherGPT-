import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase initialization. Credentials come from --dart-define, never
/// hardcoded (same pattern as the backend's API_BASE_URL) — see the README
/// for the exact flags.
///
/// Deliberately tolerant of being unconfigured: a disaster-alert tool
/// should never be fully gated behind a login screen, and a hackathon demo
/// should never break because a Supabase project wasn't set up in time.
/// If no URL/key are supplied, [isConfigured] is false, the app skips
/// straight past auth, and everyone is treated as a guest — full weather
/// functionality either way. Auth adds account features (saved locations,
/// preferences sync later) on top, it isn't a gate in front of the product.
class SupabaseService {
  SupabaseService._();

  static const String _url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) return; // no-op — app runs guest-only, see class doc
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
