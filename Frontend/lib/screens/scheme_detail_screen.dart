import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scheme.dart';
import '../theme/app_theme.dart';

class SchemeDetailScreen extends StatelessWidget {
  const SchemeDetailScreen({super.key, required this.scheme});
  final GovernmentScheme scheme;

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gold, letterSpacing: 0.4)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(scheme.category)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scheme.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _section('Benefit', Text(scheme.benefit, style: const TextStyle(fontSize: 14, height: 1.5))),
            _section('Eligibility', Text(scheme.eligibility, style: const TextStyle(fontSize: 14, height: 1.5))),
            _section(
              'Documents usually needed',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: scheme.documents
                    .map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.w700)),
                              Expanded(child: Text(d, style: const TextStyle(fontSize: 13.5))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text(
                'Confirm the current benefit amount, eligibility, and application steps on the official site — schemes are periodically updated by the government.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse(scheme.applyUrl), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open official website'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.navyDeep, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
