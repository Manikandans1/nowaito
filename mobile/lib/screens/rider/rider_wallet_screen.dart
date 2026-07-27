import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

class RiderWalletScreen extends StatefulWidget {
  const RiderWalletScreen({super.key});
  @override
  State<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends State<RiderWalletScreen> {
  String _tab = 'Payment';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NColors.secondary,
      appBar: AppBar(title: Text('Wallet & Plans', style: NTextStyles.display(18))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: NSegmentedTab(
            options: const ['Payment', 'Safe Pass'],
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _tab == 'Payment' ? _buildPayment() : _buildSafePass(),
        )),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) context.go('/rider/home');
          if (i == 1) context.go('/rider/trips');
          if (i == 3) context.go('/rider/profile');
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

  Widget _buildPayment() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    NCard(child: Row(children: [
      const Icon(Icons.credit_card, color: NColors.primary, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('UPI — Default', style: NTextStyles.body(14, weight: FontWeight.w600)),
        Text('Payment pre-authorised at booking, charged at drop-off',
            style: NTextStyles.body(11, color: NColors.muted)),
      ])),
      const NPill('Active', primary: true),
    ])),
    const SizedBox(height: 12),
    NCard(child: Row(children: [
      const Icon(Icons.account_balance_wallet_outlined,
          color: NColors.muted, size: 22),
      const SizedBox(width: 12),
      Text('Add payment method', style: NTextStyles.body(14, color: NColors.muted)),
      const Spacer(),
      const Icon(Icons.add, color: NColors.primary, size: 20),
    ])),
    const SizedBox(height: 20),
    NCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('How payment works', style: NTextStyles.body(13, weight: FontWeight.w600)),
      const SizedBox(height: 10),
      _Step('1', 'Price locked at booking — cannot change'),
      _Step('2', '₹ reserved (held) on your payment method'),
      _Step('3', 'Ride completes → amount automatically captured'),
      _Step('4', 'Receipt sent instantly · No cash needed'),
    ])),
  ]);

  Widget _buildSafePass() => Column(children: [
    _PassCard('Basic', '99', ['Guarantee fee waived on all rides',
        'Save ₹270+/month on 30 daily rides'], false),
    const SizedBox(height: 12),
    _PassCard('Plus', '199', ['Guarantee fee waived on all rides',
        'Priority reassignment during peak hours',
        'Dedicated support line'], true),
    const SizedBox(height: 16),
    NCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Why Safe Pass?', style: NTextStyles.body(13, weight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(
        'A daily commuter taking 2 rides/day pays ₹9 × 2 × 30 = ₹540/month in guarantee fees. Safe Pass Basic at ₹99/month saves you ₹441 every month.',
        style: NTextStyles.body(12, color: NColors.muted),
      ),
    ])),
  ]);
}

class _Step extends StatelessWidget {
  final String num;
  final String text;
  const _Step(this.num, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 20, height: 20,
        decoration: const BoxDecoration(
            color: NColors.primary, shape: BoxShape.circle),
        child: Center(child: Text(num,
            style: const TextStyle(color: NColors.secondary,
                fontSize: 10, fontWeight: FontWeight.w700))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: NTextStyles.body(12, color: NColors.muted))),
    ]),
  );
}

class _PassCard extends StatelessWidget {
  final String tier;
  final String price;
  final List<String> features;
  final bool highlighted;
  const _PassCard(this.tier, this.price, this.features, this.highlighted);
  @override
  Widget build(BuildContext context) => NCard(
    border: highlighted ? Border.all(color: NColors.primary) : null,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(tier, style: NTextStyles.display(16)),
        if (highlighted) ...[
          const SizedBox(width: 8),
          const NPill('Most popular', primary: true),
        ],
        const Spacer(),
        Text('₹$price', style: NTextStyles.mono(18)),
        Text('/mo', style: NTextStyles.body(12, color: NColors.muted)),
      ]),
      const SizedBox(height: 10),
      ...features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: NColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(f, style: NTextStyles.body(12))),
        ]),
      )),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: highlighted ? NColors.primary : NColors.surface,
          foregroundColor: highlighted ? NColors.secondary : NColors.white,
        ),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Safe Pass $tier — coming soon via in-app purchase'),
          backgroundColor: NColors.surface,
        )),
        child: Text('Get $tier'),
      )),
    ]),
  );
}
