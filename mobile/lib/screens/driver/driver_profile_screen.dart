import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});
  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Driver? _driver;
  bool _loading = true;
  String _tab = 'Documents';

  String get _driverId => context.read<SessionProvider>().userId ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiService.instance.getDriver(_driverId);
      if (mounted) setState(() { _driver = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      backgroundColor: NColors.secondary,
      appBar: AppBar(
          title: Text('Profile', style: NTextStyles.display(18))),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: NColors.primary))
          : Column(children: [
              // Driver header card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: NCard(child: Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: NColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      _driver != null
                          ? _driver!.name[0].toUpperCase()
                          : 'D',
                      style: NTextStyles.display(22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_driver?.name ?? 'Driver',
                        style: NTextStyles.body(16,
                            weight: FontWeight.w600)),
                    Text(_driver?.vehicleLabel ?? '',
                        style:
                            NTextStyles.body(12, color: NColors.muted)),
                    Text(_driver?.plateNumber ?? '',
                        style: NTextStyles.mono(11,
                            color: NColors.primary)),
                  ])),
                  NPill(
                    _driver?.verificationStatus == 'VERIFIED'
                        ? 'Verified ✓'
                        : _driver?.verificationStatus ?? 'Pending',
                    primary: _driver?.verificationStatus == 'VERIFIED',
                  ),
                ])),
              ),
              const SizedBox(height: 8),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NSegmentedTab(
                  options: const ['Documents', 'Support'],
                  value: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                ),
              ),

              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _tab == 'Documents'
                    ? _docs()
                    : _support(context),
              )),
            ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (i) {
          if (i == 0) context.go('/driver/home');
          if (i == 1) context.go('/driver/active-ride');
          if (i == 2) context.go('/driver/earnings');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              label: 'Active Ride'),
          BottomNavigationBarItem(
              icon: Icon(Icons.trending_up), label: 'Earnings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _docs() {
    final docs = [
      ('Driving Licence', Icons.badge_outlined, true),
      ('Vehicle RC', Icons.directions_car_outlined, true),
      ('Insurance', Icons.security_outlined,
          _driver?.verificationStatus == 'VERIFIED'),
      ('Police Verification', Icons.verified_user_outlined,
          _driver?.verificationStatus == 'VERIFIED'),
    ];
    return Column(children: [
      ...docs.map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: NCard(child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
                color: NColors.secondary, shape: BoxShape.circle),
            child: Icon(d.$2, color: NColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child:
              Text(d.$1, style: NTextStyles.body(14, weight: FontWeight.w500))),
          d.$3
              ? const NPill('Verified ✓', primary: true)
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {},
                  child: const Text('Upload',
                      style: TextStyle(fontSize: 12)),
                ),
        ])),
      )),
      const SizedBox(height: 8),
      NCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Zone Pass — Monthly',
              style: NTextStyles.body(14, weight: FontWeight.w600)),
          Text('₹999/month · Renews in 9 days',
              style: NTextStyles.body(11, color: NColors.muted)),
        ]),
        const NPill('Active', primary: true),
      ])),
      const SizedBox(height: 12),
      NRowItem(
        icon: Icons.emoji_events_outlined,
        title: 'Zone rank & badges',
        subtitle: 'Currently rank #2 in Koramangala',
      ),
      NRowItem(
        icon: Icons.logout,
        title: 'Log out',
        onTap: () async {
          await context.read<SessionProvider>().clear();
          if (!mounted) return;
          context.go('/');
        },
      ),
    ]);
  }

  Widget _support(BuildContext context) => Column(children: [
    NRowItem(
      icon: Icons.headset_mic_outlined,
      title: 'Chat with ops team',
      subtitle: 'For ride and earnings queries',
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Driver support: drivers@nowaito.in'),
        backgroundColor: NColors.surface,
      )),
    ),
    NRowItem(
      icon: Icons.flag_outlined,
      title: 'Report an incident',
      subtitle: 'Route issue, safety concern',
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Report to: safety@nowaito.in with your Trip ID'),
        backgroundColor: NColors.surface,
      )),
    ),
    NRowItem(
      icon: Icons.info_outline,
      title: 'About NoWaito',
      subtitle: 'Version 1.0.0',
    ),
  ]);
}
