import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});
  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  Driver? _driver;
  bool _loading = true;

  String get _driverId => context.read<SessionProvider>().userId ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await ApiService.instance.getDriver(_driverId);
      if (mounted) setState(() { _driver = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NColors.secondary,
      appBar: AppBar(
          title: Text('Earnings', style: NTextStyles.display(18))),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: NColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's earnings card
                  NCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TODAY',
                        style: NTextStyles.body(10, color: NColors.muted)
                            .copyWith(letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Text('₹1,252',
                        style: NTextStyles.mono(38, color: NColors.primary)),
                    Text('12 rides completed · Zone rank #2',
                        style: NTextStyles.body(12, color: NColors.muted)),
                  ])),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(children: [
                    Expanded(child: NCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('ZONE BONUS',
                              style: NTextStyles.body(9, color: NColors.muted)
                                  .copyWith(letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text('+₹30',
                              style: NTextStyles.mono(18,
                                  color: NColors.primary)),
                          Text('2 zone returns today',
                              style:
                                  NTextStyles.body(10, color: NColors.muted)),
                        ]))),
                    const SizedBox(width: 8),
                    Expanded(child: NCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('PASS COST',
                              style: NTextStyles.body(9, color: NColors.muted)
                                  .copyWith(letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text('−₹38',
                              style:
                                  NTextStyles.mono(18, color: NColors.white)),
                          Text('Monthly @ ₹999/26 days',
                              style:
                                  NTextStyles.body(10, color: NColors.muted)),
                        ]))),
                  ]),
                  const SizedBox(height: 12),

                  // vs Ola/Uber comparison
                  NCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('vs Ola / Uber today',
                        style:
                            NTextStyles.body(13, weight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _CompareRow('Gross fares (same rides)', '₹1,440',
                        '₹1,440'),
                    _CompareRow(
                        'Platform cut', '−₹360 to −₹504', '₹0 ✓',
                        highlight: true),
                    _CompareRow('Pass / commission cost', '₹0', '−₹38'),
                    _CompareRow('Fuel', '−₹180', '−₹180'),
                    _CompareRow('Zone bonus', '₹0', '+₹30', highlight: true),
                    const Divider(color: NColors.muted, height: 20),
                    _CompareRow('NET EARNED', '₹756–₹900', '₹1,252',
                        bold: true, highlight: true),
                  ])),
                  const SizedBox(height: 12),

                  // Weekly summary
                  NCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('THIS WEEK',
                        style: NTextStyles.body(10, color: NColors.muted)
                            .copyWith(letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _WeekStat('Mon', '₹1,180', true)),
                      Expanded(child: _WeekStat('Tue', '₹1,340', true)),
                      Expanded(child: _WeekStat('Wed', '₹1,252', true)),
                      Expanded(child: _WeekStat('Thu', '—', false)),
                      Expanded(child: _WeekStat('Fri', '—', false)),
                      Expanded(child: _WeekStat('Sat', '—', false)),
                    ]),
                  ])),
                  const SizedBox(height: 12),

                  // Zone pass status
                  if (_driver != null)
                    NCard(child: Row(children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Zone Pass — Monthly',
                            style: NTextStyles.body(14,
                                weight: FontWeight.w600)),
                        Text('Renews in 9 days',
                            style: NTextStyles.body(11,
                                color: NColors.muted)),
                      ]),
                      const Spacer(),
                      const NPill('Active ✓', primary: true),
                    ])),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) context.go('/driver/home');
          if (i == 1) context.go('/driver/active-ride');
          if (i == 3) context.go('/driver/profile');
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
}

class _CompareRow extends StatelessWidget {
  final String label, ola, nowaito;
  final bool highlight, bold;
  const _CompareRow(this.label, this.ola, this.nowaito,
      {this.highlight = false, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label,
          style: NTextStyles.body(12,
              color: NColors.muted,
              weight: bold ? FontWeight.w600 : FontWeight.w400))),
      SizedBox(
          width: 90,
          child: Text(ola,
              textAlign: TextAlign.right,
              style: NTextStyles.body(12, color: NColors.muted))),
      SizedBox(
          width: 90,
          child: Text(nowaito,
              textAlign: TextAlign.right,
              style: NTextStyles.body(12,
                  color: highlight ? NColors.primary : NColors.white,
                  weight: bold ? FontWeight.w700 : FontWeight.w400))),
    ]),
  );
}

class _WeekStat extends StatelessWidget {
  final String day, amount;
  final bool active;
  const _WeekStat(this.day, this.amount, this.active);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(day,
        style: NTextStyles.body(10, color: NColors.muted)),
    const SizedBox(height: 4),
    Text(amount,
        style: NTextStyles.mono(11,
            color: active ? NColors.primary : NColors.muted)),
  ]);
}
