import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_models.dart';
import 'location_service.dart';

/// Emergency SOS using the device's OWN SMS app and dialer -- no Twilio,
/// no SMS gateway, no API key. This is a real, working mechanism: it
/// hands off to whatever SMS/phone app is already on the user's device
/// with the message and number(s) pre-filled, and the user hits send/call.
/// It cannot silently auto-send in the background (Android/iOS don't allow
/// a normal app to send SMS without the user tapping send in their own
/// messaging app -- doing otherwise would need a privileged SMS permission
/// most stores restrict) -- so "pre-filled, one tap to send" is the honest
/// ceiling for a no-backend, no-paid-API implementation, not a limitation
/// of this code specifically.
class SosService {
  static const _contactsKey = 'sos_contacts_v1';
  static const _historyKey = 'sos_history_v1';
  static const _testModeKey = 'sos_test_mode_v1';
  static const int maxContacts = 3;

  final LocationService _locationService;

  SosService({LocationService? locationService}) : _locationService = locationService ?? LocationService();

  Future<List<EmergencyContact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_contactsKey) ?? [];
    final contacts = raw
        .map((s) {
          try {
            return EmergencyContact.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<EmergencyContact>()
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return contacts;
  }

  Future<void> _saveContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_contactsKey, contacts.map((c) => jsonEncode(c.toJson())).toList());
  }

  Future<void> addOrUpdateContact(EmergencyContact contact) async {
    final contacts = await getContacts();
    final withoutExisting = contacts.where((c) => c.id != contact.id).toList();
    withoutExisting.add(contact);
    await _saveContacts(withoutExisting.take(maxContacts).toList());
  }

  Future<void> deleteContact(String id) async {
    final contacts = await getContacts();
    contacts.removeWhere((c) => c.id == id);
    await _saveContacts(contacts);
  }

  Future<bool> getTestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_testModeKey) ?? false;
  }

  Future<void> setTestMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testModeKey, enabled);
  }

  Future<List<SosIncident>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    return raw
        .map((s) {
          try {
            return SosIncident.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<SosIncident>()
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _appendHistory(SosIncident incident) async {
    final history = await getHistory();
    history.insert(0, incident);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyKey,
      history.take(50).map((h) => jsonEncode(h.toJson())).toList(),
    );
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Full activation flow: get GPS location, build the SMS body with a
  /// Google Maps link, hand off to the device's SMS app addressed to every
  /// saved contact (or the user's own test number in test mode), and
  /// record the incident locally. Returns null if location couldn't be
  /// acquired (permission denied / GPS off) or no contacts are configured
  /// -- callers should show that as an actionable error, not a silent failure.
  Future<SosActivationResult> activate({String? userOwnTestNumber}) async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) {
      return SosActivationResult.failure(
        "Couldn't get your location. Make sure location access is allowed and GPS is on, then try again.",
      );
    }

    final testMode = await getTestMode();
    final contacts = await getContacts();

    final recipients = testMode
        ? (userOwnTestNumber != null && userOwnTestNumber.isNotEmpty ? [userOwnTestNumber] : <String>[])
        : contacts.map((c) => c.phone).toList();

    if (recipients.isEmpty) {
      return SosActivationResult.failure(
        testMode
            ? "Test mode is on, but no test number is set. Add one in SOS settings."
            : "No emergency contacts saved yet. Add at least one in Emergency Contacts first.",
      );
    }

    final mapsUrl = 'https://maps.google.com/?q=${position.lat},${position.lon}';
    final message = testMode
        ? '[TEST] WeatherGPT SOS test — this is only a drill. Location: $mapsUrl'
        : '\u{1F6A8} EMERGENCY: I need help. My location: $mapsUrl';

    final smsUri = Uri(
      scheme: 'sms',
      path: recipients.join(','),
      queryParameters: {'body': message},
    );

    bool smsOpened = false;
    try {
      smsOpened = await launchUrl(smsUri);
    } catch (_) {
      smsOpened = false;
    }

    await _appendHistory(SosIncident(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      latitude: position.lat,
      longitude: position.lon,
      status: testMode ? SosStatus.testMode : SosStatus.sent,
      notifiedContactNames: testMode ? ['Test number'] : contacts.map((c) => c.name).toList(),
    ));

    return SosActivationResult.success(smsOpened: smsOpened, mapsUrl: mapsUrl);
  }

  /// Opens the device dialer with the national emergency number (112)
  /// pre-filled -- the user still has to tap call, same platform
  /// restriction as SMS above.
  Future<bool> callEmergencyNumber({String number = '112'}) async {
    try {
      return await launchUrl(Uri(scheme: 'tel', path: number));
    } catch (_) {
      return false;
    }
  }
}

class SosActivationResult {
  final bool ok;
  final String? error;
  final bool smsOpened;
  final String? mapsUrl;

  const SosActivationResult._(this.ok, this.error, this.smsOpened, this.mapsUrl);

  factory SosActivationResult.success({required bool smsOpened, required String mapsUrl}) =>
      SosActivationResult._(true, null, smsOpened, mapsUrl);

  factory SosActivationResult.failure(String error) => SosActivationResult._(false, error, false, null);
}
