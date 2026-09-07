import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_theme.dart';

/// Thin, honest "you're offline" strip. For a disaster-alert app, telling
/// the user their data might be stale is a safety feature — silently
/// showing cached data with no indicator would be worse.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: AppColors.alertAmber,
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text(
                "You're offline — showing last known data",
                style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms);
      },
    );
  }
}
