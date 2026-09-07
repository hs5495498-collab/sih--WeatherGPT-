/// Sanitizes free-text user input before it's sent to the backend.
/// Not a substitute for server-side validation (Member 5 must validate
/// again there) — this is defense-in-depth plus a better UX (no silent
/// truncation surprises, no control characters breaking JSON/logs).
class InputSanitizer {
  static const int maxLength = 300;

  /// Strips control/non-printable characters (which can be used to break
  /// log parsing or smuggle unexpected bytes to the backend), collapses
  /// whitespace, and hard-caps length. Returns null if nothing usable
  /// remains after cleaning.
  static String? clean(String raw) {
    final noControlChars = raw.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    final collapsed = noControlChars.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) return null;
    return collapsed.length > maxLength ? collapsed.substring(0, maxLength) : collapsed;
  }
}
