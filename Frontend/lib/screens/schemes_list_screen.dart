import 'package:flutter/material.dart';
import '../data/government_schemes.dart';
import '../models/scheme.dart';
import '../theme/app_theme.dart';
import 'scheme_detail_screen.dart';

class SchemesListScreen extends StatefulWidget {
  const SchemesListScreen({super.key});

  @override
  State<SchemesListScreen> createState() => _SchemesListScreenState();
}

class _SchemesListScreenState extends State<SchemesListScreen> {
  String _query = '';
  String _category = 'All';

  List<String> get _categories => ['All', ...{for (final s in kGovernmentSchemes) s.category}];

  @override
  Widget build(BuildContext context) {
    final filtered = kGovernmentSchemes.where((s) {
      final matchesQuery = _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory = _category == 'All' || s.category == _category;
      return matchesQuery && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Government Schemes')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.gold.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'General reference info — always verify current benefit amounts and eligibility on the official scheme website before applying.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search schemes...',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = cat == _category;
                return ChoiceChip(
                  label: Text(cat, style: const TextStyle(fontSize: 12.5)),
                  selected: selected,
                  selectedColor: AppColors.navyDeep,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary),
                  onSelected: (_) => setState(() => _category = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No schemes match that search.', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _SchemeCard(scheme: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  const _SchemeCard({required this.scheme});
  final GovernmentScheme scheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SchemeDetailScreen(scheme: scheme)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slateLight.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(scheme.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text(scheme.category, style: const TextStyle(fontSize: 10.5, color: AppColors.gold, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(scheme.benefit, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
