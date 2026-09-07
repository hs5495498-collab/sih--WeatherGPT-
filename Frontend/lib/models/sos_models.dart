class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final int priority; // 1 = first SMS sent, 2 = second, 3 = third

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'priority': priority,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: (json['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: (json['name'] as String?)?.trim().isNotEmpty == true ? json['name'] as String : 'Contact',
      phone: (json['phone'] as String?) ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 3,
    );
  }
}

enum SosStatus { sent, testMode }

class SosIncident {
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final SosStatus status;
  final List<String> notifiedContactNames;

  const SosIncident({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.notifiedContactNames,
  });

  String get mapsUrl => 'https://maps.google.com/?q=$latitude,$longitude';

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'notified_contact_names': notifiedContactNames,
      };

  factory SosIncident.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    try {
      ts = DateTime.parse(json['timestamp'] as String);
    } catch (_) {
      ts = DateTime.now();
    }
    return SosIncident(
      id: (json['id'] as String?) ?? ts.microsecondsSinceEpoch.toString(),
      timestamp: ts,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      status: json['status'] == 'testMode' ? SosStatus.testMode : SosStatus.sent,
      notifiedContactNames:
          (json['notified_contact_names'] as List<dynamic>? ?? []).whereType<String>().toList(),
    );
  }
}
