enum AlertSeverity { low, medium, high, severe }

AlertSeverity severityFromString(String? s) {
  switch ((s ?? '').toLowerCase().trim()) {
    case 'medium':
    case 'moderate': // backend risk_service uses "MODERATE", not "medium"
      return AlertSeverity.medium;
    case 'high':
      return AlertSeverity.high;
    case 'severe':
      return AlertSeverity.severe;
    default:
      return AlertSeverity.low;
  }
}

class WeatherAlert {
  final String id;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String region;
  final DateTime issuedAt;
  final DateTime? validUntil;

  WeatherAlert({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    required this.region,
    required this.issuedAt,
    this.validUntil,
  });

  /// Defensive parsing — a malformed alert must never crash the app.
  /// Alerts are safety-critical, so we'd rather show a degraded-but-visible
  /// alert than silently drop it or throw.
  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    DateTime issuedAt;
    try {
      issuedAt = DateTime.parse(json['issued_at'] as String);
    } catch (_) {
      issuedAt = DateTime.now();
    }
    DateTime? validUntil;
    try {
      validUntil = json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null;
    } catch (_) {
      validUntil = null;
    }

    return WeatherAlert(
      id: (json['id'] as String?) ?? 'alert-${issuedAt.microsecondsSinceEpoch}',
      severity: severityFromString(json['severity'] as String?),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Weather Alert',
      message: (json['message'] as String?) ?? 'Check local conditions.',
      region: (json['region'] as String?) ?? 'Your area',
      issuedAt: issuedAt,
      validUntil: validUntil,
    );
  }
}
