import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/languages.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

/// Hidden, on-device usage dashboard. Reached from Settings by tapping the
/// Version row's leading icon 5 times and entering PIN 1234.
///
/// Deliberately built with plain Container bar rows instead of adding the
/// fl_chart package: this sandbox has no Flutter toolchain to verify a new
/// native/plugin dependency actually resolves and builds, so introducing
/// one here would be an unverified guess dressed up as a finished feature.
/// The bars below are just styled Containers — no new dependency, and
/// exactly as accurate as a chart would be for this small a dataset.
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  AnalyticsSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snap = await AnalyticsService.instance.snapshot();
    if (mounted) setState(() => _snapshot = snap);
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics (this device)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset counters',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset all counters?'),
                  content: const Text('This clears local usage counts on this device. It cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
                  ],
                ),
              );
              if (confirmed == true) {
                await AnalyticsService.instance.resetAll();
                await _load();
              }
            },
          ),
        ],
      ),
      body: snap == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.alertAmber.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.alertAmber.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'These are LOCAL counts for this device only — there is no '
                    'server-side analytics pipeline aggregating stats across users yet.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Chat messages sent', value: '${snap.chatMessagesTotal}')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(label: 'App opens', value: '${snap.appOpensTotal}')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'SOS test runs', value: '${snap.sosTestsTotal}')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(label: 'Most used language', value: _langLabel(snap.mostUsedLanguage))),
                  ],
                ),
                const SizedBox(height: 8),
                if (snap.firstLaunch != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tracking since ${DateFormat.yMMMd().format(snap.firstLaunch!)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Language usage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                if (snap.languageUsage.isEmpty)
                  const Text('No chat activity recorded yet.', style: TextStyle(color: AppColors.textSecondary))
                else
                  _BarList(
                    entries: snap.languageUsage.entries.map((e) => MapEntry(_langLabel(e.key), e.value)).toList(),
                  ),
                const SizedBox(height: 20),
                const Text('Advisory views by persona', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                if (snap.advisoryViews.isEmpty)
                  const Text('No advisory screens viewed yet.', style: TextStyle(color: AppColors.textSecondary))
                else
                  _BarList(
                    entries: snap.advisoryViews.entries
                        .map((e) => MapEntry(_capitalize(e.key), e.value))
                        .toList(),
                  ),
              ],
            ),
    );
  }

  String _langLabel(String code) => code == '—' ? '—' : languageForCode(code).label;
  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BarList extends StatelessWidget {
  const _BarList({required this.entries});
  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 1 << 30);
    return Column(
      children: sorted.map((e) {
        final fraction = e.value / maxVal;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(e.key, style: const TextStyle(fontSize: 12.5))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Container(height: 16, color: AppColors.gold.withOpacity(0.08)),
                        Container(
                          height: 16,
                          width: constraints.maxWidth * fraction,
                          color: AppColors.gold.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 24, child: Text('${e.value}', style: const TextStyle(fontSize: 12))),
            ],
          ),
        );
      }).toList(),
    );
  }
}
