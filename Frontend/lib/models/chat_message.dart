import 'weather_data.dart';
import 'weather_alert.dart';

enum Sender { user, bot }

class ChatMessage {
  final String id;
  final String text;
  final Sender sender;
  final DateTime timestamp;
  final WeatherData? weatherCard;
  final WeatherAlert? alertCard;
  final List<String> suggestions;

  /// True only when [text] was machine-translated from the backend's
  /// English reply into the chat's active language (see
  /// ApiClient.sendChatQuery / ChatQueryResponse.translated). Lets the
  /// bubble show an honest "machine-translated" caption rather than
  /// implying native-language generation.
  final bool translated;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    DateTime? timestamp,
    this.weatherCard,
    this.alertCard,
    this.suggestions = const [],
    this.translated = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
