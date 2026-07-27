import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});
  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  String _tab = 'Settings';

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      backgroundColor: NColors.secondary,
      appBar: AppBar(title: Text('Profile', style: NTextStyles.display(18))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: NSegmentedTab(
            options: const ['Settings', 'Support', 'Notifications'],
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _tab == 'Settings'
              ? _settings(session, context)
              : _tab == 'Support'
                  ? _support(context)
                  : _notifications(),
        )),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (i) {
          if (i == 0) context.go('/rider/home');
          if (i == 1) context.go('/rider/trips');
          if (i == 2) context.go('/rider/wallet');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Trips'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _settings(SessionProvider session, BuildContext context) =>
      Column(children: [
    NCard(child: Row(children: [
      CircleAvatar(
        radius: 28,
        backgroundColor: NColors.primary.withValues(alpha: 0.2),
        child: const Icon(Icons.person, color: NColors.primary, size: 28),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Rider', style: NTextStyles.body(16, weight: FontWeight.w600)),
        Text(session.userId ?? '', style: NTextStyles.body(11, color: NColors.muted)),
      ]),
    ])),
    const SizedBox(height: 12),
    NRowItem(icon: Icons.person_outline, title: 'Personal details',
        subtitle: 'Name, phone number'),
    NRowItem(icon: Icons.notifications_outlined, title: 'Notification settings',
        subtitle: 'Rides, safety alerts'),
    NRowItem(icon: Icons.lock_outline, title: 'Privacy & security'),
    NRowItem(icon: Icons.language, title: 'Language', subtitle: 'English'),
    const SizedBox(height: 8),
    NRowItem(
      icon: Icons.logout,
      title: 'Log out',
      trailing: const Icon(Icons.chevron_right, color: NColors.muted),
      onTap: () async {
        await session.clear();
        if (context.mounted) context.go('/');
      },
    ),
  ]);

  Widget _support(BuildContext context) => Column(children: [
    NRowItem(
      icon: Icons.chat_bubble_outline,
      title: 'Chat with us',
      subtitle: 'Avg reply under 2 min',
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Live chat coming soon — email support@nowaito.in'),
        backgroundColor: NColors.surface,
      )),
    ),
    NRowItem(
      icon: Icons.flag_outlined,
      title: 'Report an incident',
      subtitle: 'Safety or service issue',
      onTap: () => _showReportSheet(context),
    ),
    NRowItem(
      icon: Icons.receipt_long_outlined,
      title: 'Trip receipts',
      subtitle: 'Past invoices',
      onTap: () => context.go('/rider/trips'),
    ),
    NRowItem(
      icon: Icons.info_outline,
      title: 'About NoWaito',
      subtitle: 'Version 1.0.0',
    ),
  ]);

  Widget _notifications() => Column(children: [
    _NotifTile(
      icon: Icons.directions_car,
      title: 'Driver assigned',
      subtitle: 'When your driver is matched',
      value: true,
    ),
    _NotifTile(
      icon: Icons.location_on_outlined,
      title: 'Driver arrived',
      subtitle: 'When driver reaches pickup',
      value: true,
    ),
    _NotifTile(
      icon: Icons.verified_user_outlined,
      title: 'Safety check',
      subtitle: '5 minutes after drop-off',
      value: true,
    ),
    _NotifTile(
      icon: Icons.local_offer_outlined,
      title: 'Offers & updates',
      subtitle: 'Safe Pass deals, new zones',
      value: false,
    ),
  ]);

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Report an incident', style: NTextStyles.display(16)),
          const SizedBox(height: 12),
          ...['Driver misconduct', 'Route deviation',
              'Safety concern', 'Overcharge'].map((r) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Text(r, style: NTextStyles.body(13)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: NColors.muted, size: 18),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('All reports are reviewed by our ops team within 24 hours.',
              style: NTextStyles.body(11, color: NColors.muted)),
        ]),
      ),
    );
  }
}

class _NotifTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  const _NotifTile({required this.icon, required this.title,
      required this.subtitle, required this.value});
  @override
  State<_NotifTile> createState() => _NotifTileState();
}

class _NotifTileState extends State<_NotifTile> {
  late bool _val;
  @override
  void initState() { super.initState(); _val = widget.value; }
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: NCard(child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(
            color: NColors.secondary, shape: BoxShape.circle),
        child: Icon(widget.icon, color: NColors.primary, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(widget.title, style: NTextStyles.body(14, weight: FontWeight.w500)),
        Text(widget.subtitle, style: NTextStyles.body(11, color: NColors.muted)),
      ])),
      Switch(
        value: _val,
        onChanged: (v) => setState(() => _val = v),
        activeColor: NColors.primary,
      ),
    ])),
  );
}
