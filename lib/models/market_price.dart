class MarketPrice {
  final String market;
  final String state;
  final String district;
  final String commodity;
  final String variety;
  final double minPriceRsPerQuintal;
  final double maxPriceRsPerQuintal;
  final double modalPriceRsPerQuintal;
  final DateTime? arrivalDate;

  const MarketPrice({
    required this.market,
    required this.state,
    required this.district,
    required this.commodity,
    required this.variety,
    required this.minPriceRsPerQuintal,
    required this.maxPriceRsPerQuintal,
    required this.modalPriceRsPerQuintal,
    this.arrivalDate,
  });

  /// Parses one record from data.gov.in's Agmarknet "Variety-wise Daily
  /// Market Prices" resource. Field names below match that dataset's
  /// documented schema; defensive parsing throughout so a malformed or
  /// partial record is skipped rather than crashing the whole list.
  static MarketPrice? fromRecord(Map<String, dynamic> json) {
    final market = json['market'] as String?;
    final commodity = json['commodity'] as String?;
    if (market == null || commodity == null) return null;

    DateTime? arrivalDate;
    final dateStr = json['arrival_date'] as String?;
    if (dateStr != null) {
      // Agmarknet dates are DD/MM/YYYY, not ISO.
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        arrivalDate = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      }
    }

    return MarketPrice(
      market: market,
      state: (json['state'] as String?) ?? '',
      district: (json['district'] as String?) ?? '',
      commodity: commodity,
      variety: (json['variety'] as String?) ?? '',
      minPriceRsPerQuintal: _asDouble(json['min_price']),
      maxPriceRsPerQuintal: _asDouble(json['max_price']),
      modalPriceRsPerQuintal: _asDouble(json['modal_price']),
      arrivalDate: arrivalDate,
    );
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
