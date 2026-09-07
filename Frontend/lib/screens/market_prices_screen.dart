import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/market_price.dart';
import '../services/market_price_service.dart';
import '../theme/app_theme.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  final _service = MarketPriceService();
  final _commodityController = TextEditingController(text: 'Wheat');
  String? _state;
  List<MarketPrice> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  static const _states = [
    'Rajasthan', 'Madhya Pradesh', 'Uttar Pradesh', 'Punjab', 'Haryana',
    'Maharashtra', 'Gujarat', 'Bihar', 'West Bengal', 'Karnataka',
  ];

  @override
  void dispose() {
    _commodityController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final commodity = _commodityController.text.trim();
    if (commodity.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    final result = await _service.fetchPrices(commodity: commodity, state: _state);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = result.prices;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Market Prices')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.gold.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'Live mandi prices from the Government\'s AGMARKNET open dataset (data.gov.in). '
              'Uses a shared demo API key — if results seem unavailable, this is likely rate-limited; add your own free key from data.gov.in.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _commodityController,
                  decoration: const InputDecoration(labelText: 'Commodity', hintText: 'Wheat, Rice, Cotton...', prefixIcon: Icon(Icons.grass_rounded)),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _state,
                        decoration: const InputDecoration(labelText: 'State (optional)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Any state')),
                          ..._states.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                        ],
                        onChanged: (v) => setState(() => _state = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _loading ? null : _search,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.navyDeep, padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20)),
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: !_searched
                ? const Center(child: Text('Search a commodity to see nearby mandi prices.', style: TextStyle(color: AppColors.textSecondary)))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _PriceCard(price: _results[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price});
  final MarketPrice price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slateLight.withOpacity(0.25))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price.market, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                Text('${price.district}, ${price.state}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (price.variety.isNotEmpty)
                  Text(price.variety, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                if (price.arrivalDate != null)
                  Text(DateFormat.yMMMd().format(price.arrivalDate!), style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\u20b9${price.modalPriceRsPerQuintal.round()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.gold)),
              const Text('per quintal', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${price.market}, ${price.district}, ${price.state}')}'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.navigation_rounded, size: 14),
                label: const Text('Navigate', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
