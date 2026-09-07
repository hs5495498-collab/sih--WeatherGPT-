import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_price.dart';

/// Fetches mandi (market) prices from the Government of India's Open
/// Government Data platform, resource "Variety-wise Daily Market Prices
/// Data of Commodity" (the dataset AGMARKNET publishes through data.gov.in).
///
/// HONESTY CORRECTION vs. a feature list you may have seen claiming this is
/// "a public API, no auth required, no backend needed": that's not quite
/// right. data.gov.in's APIs DO require an api-key query parameter for
/// every request. The good news is data.gov.in publishes a shared public
/// demo key in their own official documentation
/// (579b464db66ec23bdd000001cdd3946e44ce109f4d51b5b613ffdc7) that works
/// across many of their open datasets with a modest shared rate limit --
/// that's what this defaults to, via `--dart-define=AGMARKNET_API_KEY=...`
/// if you have your own free key from data.gov.in (recommended for
/// anything beyond a demo, since the shared key's rate limit is shared
/// across everyone using it).
///
/// A SECOND honesty note: the exact resource id below was written from
/// memory, not verified against a live call from this environment (this
/// sandbox's network egress doesn't include api.data.gov.in). If it 404s
/// or returns no records for a real query, that's the first thing to
/// check -- search data.gov.in for "Variety-wise Daily Market Prices" to
/// confirm/replace the id via `--dart-define=AGMARKNET_RESOURCE_ID=...`.
/// This code fails honestly either way: no prices fetched means an empty
/// list and a visible error in the UI, never fabricated numbers.
class MarketPriceService {
  static const _defaultApiKey = '579b464db66ec23bdd000001cdd3946e44ce109f4d51b5b613ffdc7';
  static const _defaultResourceId = '9ef84268-d588-465a-a308-a864a43d0070';

  static const _apiKey = String.fromEnvironment('AGMARKNET_API_KEY', defaultValue: _defaultApiKey);
  static const _resourceId = String.fromEnvironment('AGMARKNET_RESOURCE_ID', defaultValue: _defaultResourceId);

  Future<MarketPriceQueryResult> fetchPrices({required String commodity, String? state}) async {
    try {
      final uri = Uri.parse('https://api.data.gov.in/resource/$_resourceId').replace(queryParameters: {
        'api-key': _apiKey,
        'format': 'json',
        'limit': '50',
        'filters[commodity]': commodity,
        if (state != null && state.isNotEmpty) 'filters[state]': state,
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        return MarketPriceQueryResult.failure(
          'The market-price service returned an error (HTTP ${res.statusCode}). '
          'This dataset needs verifying -- see MarketPriceService\'s doc comment.',
        );
      }

      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final records = (json['records'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MarketPrice.fromRecord)
          .whereType<MarketPrice>()
          .toList();

      if (records.isEmpty) {
        return MarketPriceQueryResult.failure(
          'No live price records found for "$commodity"${state != null ? ' in $state' : ''}. '
          'Try a different commodity name, or check the resource id (see doc comment).',
        );
      }

      return MarketPriceQueryResult.success(records);
    } catch (_) {
      return const MarketPriceQueryResult.failure(
        "Couldn't reach the market-price service — check your connection and try again.",
      );
    }
  }
}

class MarketPriceQueryResult {
  final List<MarketPrice> prices;
  final String? error;

  const MarketPriceQueryResult._(this.prices, this.error);

  const MarketPriceQueryResult.success(this.prices) : error = null;
  const MarketPriceQueryResult.failure(String message)
      : prices = const [],
        error = message;

  bool get ok => error == null;
}
