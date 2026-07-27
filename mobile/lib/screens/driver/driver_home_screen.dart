import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../services/session_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});
  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _online = false;
  int? _queuePos;
  Driver? _driver;
  bool _loading = false;
  Timer? _pollTimer;
  String _distancePref = 'Medium';
  final _bands = ['Short', 'Medium', 'Long'];

  String get _driverId => context.read<SessionProvider>().userId ?? '';

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    try {
      final d = await ApiService.instance.getDriver(_driverId);
      if (mounted) setState(() => _driver = d);
    } catch (_) {}
  }

  Future<void> _toggle() async {
    setState(() => _loading = true);
    try {
      if (!_online) {
        await ApiService.instance.goOnline(_driverId);
        setState(() => _online = true);
        _startPolling();
      } else {
        await ApiService.instance.goOffline(_driverId);
        _stopPolling();
        setState(() { _online = false; _queuePos = null; });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: NColors.surface,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!_online || !mounted) return;
      try {
        final pos = await ApiService.instance.queuePosition(_driverId);
        if (mounted) setState(() => _queuePos = pos);

        // Check for newly assigned trip and notify
        final trip = await ApiService.instance.getActiveTripForDriver(_driverId);
        if (trip != null && (trip.isAssigned || trip.isArrived || trip.isInProgress)) {
          NotificationService.instance.rideAssignedToDriver(
            trip.pickupLabel.isNotEmpty ? trip.pickupLabel : 'Pickup point',
            trip.lockedFare,
          );
          _stopPolling();
          if (mounted) context.go('/driver/active-ride');
        }
      } catch (_) {}
    });
  }

  void _stopPolling() { _pollTimer?.cancel(); _pollTimer = null; }

  @override
  void dispose() { _stopPolling(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final driverName = _driver?.name ?? 'Driver';

    return Scaffold(
      backgroundColor: NColors.secondary,
      appBar: AppBar(
        title: Text('Good morning, ${driverName.split(' ').first}',
            style: NTextStyles.display(18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: NColors.muted),
            onPressed: () async {
              if (_online) await ApiService.instance.goOffline(_driverId);
              _stopPolling();
              await context.read<SessionProvider>().clear();
              if (!mounted) return;
              context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Online / offline toggle
          NCard(child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _online ? "You're online" : "You're offline",
                  style: NTextStyles.body(14, weight: FontWeight.w600),
                ),
                if (_online)
                  Text('Zone: Koramangala',
                      style: NTextStyles.body(11, color: NColors.muted)),
                if (!_online)
                  Text('Go online to receive rides',
                      style: NTextStyles.body(11, color: NColors.muted)),
              ],
            )),
            if (_loading)
              const SizedBox(
                width: 36, height: 20,
                child: CircularProgressIndicator(
                    color: NColors.primary, strokeWidth: 2),
              )
            else
              Switch(
                value: _online,
                onChanged: (_) => _toggle(),
                activeColor: NColors.primary,
                inactiveTrackColor: NColors.muted.withValues(alpha: 0.3),
              ),
          ])),
          const SizedBox(height: 12),

          // Queue position
          if (_online && _queuePos != null) ...[
            NCard(
              border: Border.all(color: NColors.primary.withValues(alpha: 0.4)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.people_outline,
                      color: NColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Position $_queuePos in zone queue',
                      style: NTextStyles.body(14, weight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                Text(
                  'Next ride assigns automatically — no action needed',
                  textAlign: TextAlign.center,
                  style: NTextStyles.body(12, color: NColors.muted),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Driver stats
          if (_driver != null) ...[
            Row(children: [
              Expanded(child: NCard(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('VEHICLE',
                      style: NTextStyles.body(9, color: NColors.muted)
                          .copyWith(letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(_driver!.vehicleLabel,
                      style: NTextStyles.body(13, weight: FontWeight.w600)),
                  Text(_driver!.plateNumber,
                      style: NTextStyles.body(11, color: NColors.muted)),
                ]),
              )),
              const SizedBox(width: 8),
              Expanded(child: NCard(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('STATUS',
                      style: NTextStyles.body(9, color: NColors.muted)
                          .copyWith(letterSpacing: 1)),
                  const SizedBox(height: 4),
                  NPill(
                    _driver!.verificationStatus == 'VERIFIED'
                        ? 'Verified ✓'
                        : _driver!.verificationStatus,
                    primary: _driver!.verificationStatus == 'VERIFIED',
                  ),
                ]),
              )),
            ]),
            const SizedBox(height: 12),
          ],

          // Distance preference
          Text('RIDE PREFERENCE',
              style: NTextStyles.body(10, color: NColors.muted)
                  .copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 8),
          NSegmentedTab(
            options: _bands,
            value: _distancePref,
            onChanged: (v) => setState(() => _distancePref = v),
          ),
          const SizedBox(height: 16),

          const NMapPlaceholder(height: 160),
          const SizedBox(height: 20),

          if (!_online)
            NPrimaryButton('Go Online', onPressed: _loading ? null : _toggle),

          const SizedBox(height: 16),
          Text(
            'Tip: book a ride from the Rider app while online — the assignment engine matches it within seconds. Check the Active Ride tab.',
            style: NTextStyles.body(10, color: NColors.muted),
          ),
        ]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) context.go('/driver/active-ride');
          if (i == 2) context.go('/driver/earnings');
          if (i == 3) context.go('/driver/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined), label: 'Active Ride'),
          BottomNavigationBarItem(
              icon: Icon(Icons.trending_up), label: 'Earnings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
