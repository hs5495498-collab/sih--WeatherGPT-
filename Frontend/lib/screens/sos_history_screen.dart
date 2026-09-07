import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/sos_models.dart';
import '../services/sos_service.dart';
import '../theme/app_theme.dart';

class SosHistoryScreen extends StatefulWidget {
  const SosHistoryScreen({super.key});

  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  final _sos = SosService();
  List<SosIncident> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _sos.getHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS history'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear history',
              onPressed: () async {
                await _sos.clearHistory();
                await _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No SOS activations yet — this stays empty until you actually use the SOS button.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final h = _history[i];
                    final isTest = h.status == SosStatus.testMode;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (isTest ? AppColors.alertAmber : AppColors.alertRed).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: (isTest ? AppColors.alertAmber : AppColors.alertRed).withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(isTest ? Icons.science_outlined : Icons.emergency_share_rounded,
                              color: isTest ? AppColors.alertAmber : AppColors.alertRed, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTest ? 'Test activation' : 'SOS sent',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(DateFormat('MMM d, y \u2022 h:mm a').format(h.timestamp),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text('Notified: ${h.notifiedContactNames.join(', ')}',
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(h.mapsUrl, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
