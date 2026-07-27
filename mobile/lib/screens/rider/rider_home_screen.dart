import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/session_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

const _pickup = (lat: 12.9352, lng: 77.6146, label: 'Forum Mall Rd, Koramangala');
const _drop   = (lat: 12.9699, lng: 77.7499, label: 'Whitefield Tech Park');
const _distKm = 9.4;

const _vehicles = [
  (id: 'BIKE', label: 'Bike',  icon: Icons.two_wheeler),
  (id: 'AUTO', label: 'Auto',  icon: Icons.electric_rickshaw),
  (id: 'CAR',  label: 'Car',   icon: Icons.directions_car),
];

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});
  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  String _selected = 'CAR';
  Map<String, Quote> _quotes = {};
  bool _loadingQuotes = false;
  bool _booking = false;
  String? _error;

  // Fetch all three quotes then open the sheet
  Future<void> _openSheet() async {
    setState(() { _loadingQuotes = true; _error = null; });
    try {
      final results = await Future.wait(
        _vehicles.map((v) => ApiService.instance.getQuote(
          v.id, _distKm, peakActive: v.id == 'BIKE',
        )),
      );
      if (!mounted) return;
      final next = <String, Quote>{};
      for (int i = 0; i < _vehicles.length; i++) {
        next[_vehicles[i].id] = results[i];
      }
      setState(() { _quotes = next; _loadingQuotes = false; });
      // Only open sheet after quotes are loaded
      _showVehicleSheet();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingQuotes = false;
        _error = 'Could not load prices. Is the backend running?';
      });
    }
  }

  void _showVehicleSheet() {
    // Capture navigator before sheet opens so context stays valid
    final nav = GoRouter.of(context);
    final riderId = context.read<SessionProvider>().userId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          final q = _quotes[_selected];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: NColors.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Choose your ride', style: NTextStyles.display(16)),
                const SizedBox(height: 4),
                Text(
                  '${_pickup.label} → ${_drop.label}',
                  style: NTextStyles.body(12, color: NColors.muted),
                ),
                const SizedBox(height: 16),

                // Vehicle cards
                ..._vehicles.map((v) {
                  final isSel = _selected == v.id;
                  final vq = _quotes[v.id];
                  return GestureDetector(
                    onTap: () => setSheet(() => _selected = v.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? NColors.primary.withValues(alpha: 0.1)
                            : NColors.secondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel
                              ? NColors.primary
                              : NColors.muted.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(
                            color: NColors.surface, shape: BoxShape.circle,
                          ),
                          child: Icon(
                            v.icon,
                            color: isSel ? NColors.primary : NColors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.label,
                                style: NTextStyles.body(14,
                                    weight: FontWeight.w600)),
                          ],
                        )),
                        Text(
                          vq != null ? '₹${vq.total}' : '—',
                          style: NTextStyles.mono(15,
                              color: isSel ? NColors.primary : NColors.white),
                        ),
                      ]),
                    ),
                  );
                }),

                // Price breakdown
                if (q != null) ...[
                  const SizedBox(height: 4),
                  NCard(child: Column(children: [
                    _PriceRow('Ride fare', '₹${q.fare}'),
                    const SizedBox(height: 4),
                    _PriceRow('Guarantee fee', '₹${q.guaranteeFee}'),
                    if (q.peakActive) ...[
                      const SizedBox(height: 8),
                      const NPill('Peak Rate active — included above',
                          primary: true),
                    ],
                  ])),
                  const SizedBox(height: 12),
                  Center(child: NPriceBadge(amount: q.total, large: true)),
                  const SizedBox(height: 6),
                  Text(
                    '₹${q.total} reserved now · charged only after the ride completes',
                    textAlign: TextAlign.center,
                    style: NTextStyles.body(11, color: NColors.muted),
                  ),
                ],
                const SizedBox(height: 16),

                NPrimaryButton(
                  _booking
                      ? 'Booking...'
                      : 'Book $_selected — Price Locked',
                  loading: _booking,
                  onPressed: q == null || _booking
                      ? null
                      : () => _confirmBooking(
                            sheetCtx: sheetCtx,
                            nav: nav,
                            riderId: riderId,
                            setSheet: setSheet,
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmBooking({
    required BuildContext sheetCtx,
    required GoRouter nav,
    required String? riderId,
    required StateSetter setSheet,
  }) async {
    setSheet(() => _booking = true);
    setState(() => _booking = true);
    try {
      final zones = await ApiService.instance.listZones();
      if (zones.isEmpty) throw Exception('No zones found. Is the backend seeded?');
      final zone = zones.first;
      final trip = await ApiService.instance.createBooking({
        'riderId': riderId,
        'zoneId': zone.id,
        'vehicleType': _selected,
        'pickupLat': _pickup.lat, 'pickupLng': _pickup.lng,
        'pickupLabel': _pickup.label,
        'dropLat': _drop.lat, 'dropLng': _drop.lng,
        'dropLabel': _drop.label,
        'distanceKm': _distKm,
        'peakActive': _selected == 'BIKE',
      });
      if (!mounted) return;
      Navigator.of(sheetCtx).pop(); // close sheet using sheet's context
      nav.go('/rider/active-trip',
          extra: {'tripId': trip.id, 'vehicle': _selected});
    } catch (e) {
      if (!mounted) return;
      setSheet(() => _booking = false);
      setState(() => _booking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: NColors.surface,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NColors.secondary,
      appBar: AppBar(
        title: Text('NoWaito', style: NTextStyles.display(20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: NColors.muted),
            onPressed: () async {
              await context.read<SessionProvider>().clear();
              if (!mounted) return;
              context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Where to, today?', style: NTextStyles.display(22)),
            const SizedBox(height: 14),

            // Pickup field
            NCard(child: Row(children: [
              const Icon(Icons.my_location, color: NColors.primary, size: 16),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PICKUP',
                    style: NTextStyles.body(10, color: NColors.muted)
                        .copyWith(letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Text(_pickup.label, style: NTextStyles.body(14)),
              ]),
            ])),
            const SizedBox(height: 8),

            // Drop field — tap to open sheet
            GestureDetector(
              onTap: _loadingQuotes ? null : _openSheet,
              child: NCard(child: Row(children: [
                const Icon(Icons.search, color: NColors.primary, size: 16),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DROP',
                        style: NTextStyles.body(10, color: NColors.muted)
                            .copyWith(letterSpacing: 1.5)),
                    const SizedBox(height: 2),
                    Text(_drop.label, style: NTextStyles.body(14)),
                  ],
                )),
                if (_loadingQuotes)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: NColors.primary, strokeWidth: 2),
                  ),
              ])),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: NTextStyles.body(12, color: NColors.error)),
            ],

            const SizedBox(height: 16),
            const NMapPlaceholder(height: 240),
            const SizedBox(height: 14),

            const Row(children: [
              NPill('23 drivers nearby', primary: true),
              SizedBox(width: 8),
              NPill('Koramangala zone'),
            ]),
            const SizedBox(height: 20),

            NPrimaryButton(
              _loadingQuotes ? 'Loading prices...' : 'See ride options',
              loading: _loadingQuotes,
              onPressed: _loadingQuotes ? null : _openSheet,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) context.go('/rider/trips');
          if (i == 2) context.go('/rider/wallet');
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
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: NTextStyles.body(13, color: NColors.muted)),
      Text(value, style: NTextStyles.body(13)),
    ],
  );
}
