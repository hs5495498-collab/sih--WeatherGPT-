import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'alerts_dashboard_screen.dart';
import 'auth/login_screen.dart';
import 'market_prices_screen.dart';
import 'persona_advisory_screen.dart';
import 'schemes_list_screen.dart';
import 'settings_screen.dart';
import 'showcase_screen.dart';
import 'sos_screen.dart';
import 'weather_map_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Drawer(
      backgroundColor: AppColors.navyDeep,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  const AppLogo(size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WeatherGPT',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          auth.isAuthenticated ? (auth.user?.email ?? 'Signed in') : 'Guest',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Ask WeatherGPT',
              onTap: () {
                context.read<NavigationProvider>().goToTab(0);
                Navigator.of(context).pop();
              },
            ),
            _DrawerItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              onTap: () {
                context.read<NavigationProvider>().goToTab(1);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.warning_amber_rounded,
              label: 'Weather Alerts',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertsDashboardScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.emergency_share_rounded,
              label: 'Emergency SOS',
              iconColor: const Color(0xFFE0837E),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SosScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.account_balance_rounded,
              label: 'Government Schemes',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SchemesListScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.groups_2_rounded,
              label: 'Persona Advisory',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PersonaAdvisoryScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.map_rounded,
              label: 'Weather Radar Map',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeatherMapScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.storefront_rounded,
              label: 'Market Prices',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarketPricesScreen()));
              },
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.info_outline_rounded,
              label: 'About',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShowcaseScreen()));
              },
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const Spacer(),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            _DrawerItem(
              icon: auth.isAuthenticated ? Icons.logout_rounded : Icons.login_rounded,
              label: auth.isAuthenticated ? 'Sign out' : 'Sign in',
              onTap: () async {
                Navigator.of(context).pop();
                if (auth.isAuthenticated) {
                  await auth.signOut();
                } else if (auth.isSupabaseConfigured) {
                  if (context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                  }
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.iconColor});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white.withOpacity(0.85), size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14.5)),
      onTap: onTap,
      dense: true,
    );
  }
}
