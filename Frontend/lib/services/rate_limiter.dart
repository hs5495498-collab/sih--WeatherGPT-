/// Simple sliding-window rate limiter. Runs entirely client-side — it does
/// NOT replace server-side rate limiting (Member 6 should still enforce
/// limits on the backend), but it stops one impatient tap-storm from
/// firing a dozen concurrent requests at a hackathon demo network/backend,
/// and gives the user an honest "slow down" message instead of a silent
/// pile-up.
class RateLimiter {
  RateLimiter({
    this.maxRequests = 8,
    this.window = const Duration(minutes: 1),
    this.minGap = const Duration(milliseconds: 700),
  });

  final int maxRequests;
  final Duration window;
  final Duration minGap;

  final List<DateTime> _timestamps = [];

  /// Returns null if the request is allowed (and records it).
  /// Returns a user-facing reason string if it should be blocked.
  String? checkAndRecord() {
    final now = DateTime.now();

    if (_timestamps.isNotEmpty && now.difference(_timestamps.last) < minGap) {
      return "You're asking faster than I can think — give me a second.";
    }

    _timestamps.removeWhere((t) => now.difference(t) > window);
    if (_timestamps.length >= maxRequests) {
      return "That's a lot of questions in a short time — please wait a "
          "moment before asking again.";
    }

    _timestamps.add(now);
    return null;
  }
}
