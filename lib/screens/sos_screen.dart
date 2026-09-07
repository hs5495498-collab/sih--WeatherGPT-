import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sos_models.dart';
import '../services/analytics_service.dart';
import '../services/sos_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncy.dart';
import 'sos_history_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final _sos = SosService();
  List<EmergencyContact> _contacts = [];
  bool _testMode = false;
  final _testNumberController = TextEditingController();
  bool _loading = true;
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _testNumberController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final contacts = await _sos.getContacts();
    final testMode = await _sos.getTestMode();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _testMode = testMode;
      _loading = false;
    });
  }

  Future<void> _confirmAndActivate() async {
    HapticFeedback.heavyImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SosCountdownDialog(seconds: 3),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _activating = true);
    final result = await _sos.activate(
      userOwnTestNumber: _testNumberController.text.trim().isEmpty ? null : _testNumberController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _activating = false);

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    if (_testMode) unawaited(AnalyticsService.instance.recordSosTestTriggered());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.smsOpened
          ? 'SMS app opened with your location — tap send.'
          : "Couldn't open the SMS app automatically. Your location: ${result.mapsUrl}"),
      duration: const Duration(seconds: 6),
    ));
  }

  Future<void> _call112() async {
    final ok = await _sos.callEmergencyNumber();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the dialer on this device.")),
      );
    }
  }

  Future<void> _addOrEditContact({EmergencyContact? existing}) async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => _ContactEditDialog(existing: existing, nextPriority: _contacts.length + 1),
    );
    if (result == null) return;
    await _sos.addOrUpdateContact(result);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'SOS history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SosHistoryScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_testMode)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.alertAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.science_outlined, size: 18, color: AppColors.alertAmber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Test mode is ON — SOS will message your own test number, not real contacts.',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                Center(
                  child: Column(
                    children: [
                      Bouncy(
                        onTap: null, // deliberately not a tap target — see long-press below
                        child: GestureDetector(
                          onLongPress: _activating ? null : _confirmAndActivate,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: AppColors.alertRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppColors.alertRed.withOpacity(0.45), blurRadius: 24, spreadRadius: 2),
                              ],
                            ),
                            child: _activating
                                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.emergency_share_rounded, color: Colors.white, size: 44),
                                      SizedBox(height: 6),
                                      Text('SOS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Long-press to activate', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _call112,
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Call 112 (national emergency)'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.alertRed, side: const BorderSide(color: AppColors.alertRed)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Emergency contacts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('${_contacts.length}/${SosService.maxContacts}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "SOS opens your phone's own SMS app with these numbers and your location pre-filled — you tap send. No third-party SMS service is used.",
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                ..._contacts.map((c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: AppColors.navy, child: Text('${c.priority}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                      title: Text(c.name),
                      subtitle: Text(c.phone),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _addOrEditContact(existing: c)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            onPressed: () async {
                              await _sos.deleteContact(c.id);
                              await _load();
                            },
                          ),
                        ],
                      ),
                    )),
                if (_contacts.length < SosService.maxContacts)
                  TextButton.icon(
                    onPressed: () => _addOrEditContact(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add emergency contact'),
                  ),
                const SizedBox(height: 20),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _testMode,
                  activeColor: AppColors.gold,
                  title: const Text('Test mode'),
                  subtitle: const Text('Sends to your own number instead of real contacts', style: TextStyle(fontSize: 12)),
                  onChanged: (v) async {
                    await _sos.setTestMode(v);
                    setState(() => _testMode = v);
                  },
                ),
                if (_testMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: TextField(
                      controller: _testNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Your test phone number'),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SosCountdownDialog extends StatefulWidget {
  const _SosCountdownDialog({required this.seconds});
  final int seconds;

  @override
  State<_SosCountdownDialog> createState() => _SosCountdownDialogState();
}

class _SosCountdownDialogState extends State<_SosCountdownDialog> {
  late int _remaining = widget.seconds;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_remaining <= 1) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _remaining -= 1);
      _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sending SOS in...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_remaining', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.alertRed)),
          const SizedBox(height: 8),
          const Text('Tap Cancel to stop', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
      ],
    );
  }
}

class _ContactEditDialog extends StatefulWidget {
  const _ContactEditDialog({this.existing, required this.nextPriority});
  final EmergencyContact? existing;
  final int nextPriority;

  @override
  State<_ContactEditDialog> createState() => _ContactEditDialogState();
}

class _ContactEditDialogState extends State<_ContactEditDialog> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _phoneController = TextEditingController(text: widget.existing?.phone ?? '');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add contact' : 'Edit contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number', hintText: '+91XXXXXXXXXX'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final phone = _phoneController.text.trim();
            if (name.isEmpty || phone.isEmpty) return;
            Navigator.of(context).pop(EmergencyContact(
              id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
              name: name,
              phone: phone,
              priority: widget.existing?.priority ?? widget.nextPriority,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
