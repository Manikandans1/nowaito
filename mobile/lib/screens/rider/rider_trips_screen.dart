import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

class RiderTripsScreen extends StatefulWidget {
  const RiderTripsScreen({super.key});
  @override
  State<RiderTripsScreen> createState() => _RiderTripsScreenState();
}

class _RiderTripsScreenState extends State<RiderTripsScreen> {
  List<Trip>? _trips;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // We don't have a rider trips endpoint yet — show a helpful state
      // The endpoint pattern would be GET /api/trips/rider/{riderId}
      // For now show the demo data with a clear label
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() { _trips = []; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  IconData _vehicleIcon(String type) {
    switch (type.toUpperCase()) {
      case 'BIKE': return Icons.two_wheeler;
      case 'AUTO': return Icons.electric_rickshaw;
      default: return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NColors.secondary,
      appBar: AppBar(title: Text('Trip History', style: NTextStyles.display(18))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: NColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: NTextStyles.body(13, color: NColors.muted)))
              : _trips!.isEmpty
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        const Icon(Icons.history, color: NColors.muted, size: 56),
                        const SizedBox(height: 16),
                        Text('No trips yet',
                            style: NTextStyles.display(18)),
                        const SizedBox(height: 8),
                        Text(
                          'Your completed rides will appear here after your first trip.',
                          textAlign: TextAlign.center,
                          style: NTextStyles.body(13, color: NColors.muted),
                        ),
                        const SizedBox(height: 24),
                        NPrimaryButton('Book a ride',
                            onPressed: () => context.go('/rider/home')),
                      ]),
                    ))
                  : RefreshIndicator(
                      color: NColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _trips!.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final t = _trips![i];
                          return NCard(child: Row(children: [
                            Container(
                              width: 42, height: 42,
                              decoration: const BoxDecoration(
                                color: NColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_vehicleIcon(t.vehicleType),
                                  color: NColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.dropLabel.isNotEmpty
                                    ? t.dropLabel : 'Trip',
                                    style: NTextStyles.body(14,
                                        weight: FontWeight.w600)),
                                Text(t.pickupLabel,
                                    style: NTextStyles.body(12,
                                        color: NColors.muted)),
                              ],
                            )),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${t.total}',
                                    style: NTextStyles.mono(14)),
                                Text(t.status.toLowerCase(),
                                    style: NTextStyles.body(11,
                                        color: NColors.muted)),
                              ],
                            ),
                          ]));
                        },
                      ),
                    ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) context.go('/rider/home');
          if (i == 2) context.go('/rider/wallet');
          if (i == 3) context.go('/rider/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Trips'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
