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

class DriverActiveRideScreen extends StatefulWidget {
  const DriverActiveRideScreen({super.key});
  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  Trip? _trip;
  Driver? _driver;
  Timer? _timer;
  bool _busy = false;
  String? _prevStatus;

  String get _driverId => context.read<SessionProvider>().userId ?? '';

  @override
  void initState() {
    super.initState();
    _loadDriver();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _loadDriver() async {
    try {
      final d = await ApiService.instance.getDriver(_driverId);
      if (mounted) setState(() => _driver = d);
    } catch (_) {}
  }

  Future<void> _poll() async {
    try {
      final t = await ApiService.instance.getActiveTripForDriver(_driverId);
      if (!mounted) return;

      if (t != null && t.status != _prevStatus) {
        _onStatusChange(t);
        _prevStatus = t.status;
      }

      setState(() => _trip = t);
    } catch (_) {}
  }

  void _onStatusChange(Trip t) {
    if (t.isCompleted) {
      NotificationService.instance.tripCompletedDriver(t.lockedFare);
    }
  }

  Future<void> _act(Future<Trip> Function() fn) async {
    setState(() => _busy = true);
    try {
      final t = await fn();
      if (mounted) setState(() => _trip = t);
      // After complete, return to home after short delay
      if (t.isCompleted) {
        _timer?.cancel();
        NotificationService.instance.tripCompletedDriver(t.lockedFare);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/driver/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: NColors.surface,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _noShow() async {
    final t = _trip;
    if (t == null) return;
    setState(() => _busy = true);
    try {
      await ApiService.instance.driverNoShow(t.id);
      NotificationService.instance.cancelledByRider();
      _timer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Marked as No Show. Returning to queue.'),
          backgroundColor: NColors.surface,
        ));
        context.go('/driver/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: NColors.surface,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showEmergencySheet() {
    final t = _trip;
    final d = _driver;
    if (t == null) return;

    // Check if emergency cancel quota is used
    final quotaAvailable = d?.emergencyCancelAvailable ?? true;
    final usedToday = !quotaAvailable;

    String? selectedReason;
    showModalBottomSheet(
      context: context,
      backgroundColor: NColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: NColors.muted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 16),
          Row(children: [
            Text('Emergency Cancel', style: NTextStyles.display(15)),
            const Spacer(),
            NPill(
              usedToday ? 'Quota used today' : '1 available today',
              primary: !usedToday,
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            'Valid emergencies only. Photo proof required within 2 minutes.',
            style: NTextStyles.body(12, color: NColors.muted),
          ),
          const SizedBox(height: 16),

          ...['Vehicle breakdown', 'Medical emergency', 'Accident'].map((r) =>
            GestureDetector(
              onTap: () => setS(() => selectedReason = r),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedReason == r
                      ? NColors.primary.withValues(alpha: 0.1)
                      : NColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedReason == r
                        ? NColors.primary
                        : NColors.muted.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(children: [
                  Text(r, style: NTextStyles.body(13)),
                  const Spacer(),
                  if (selectedReason == r)
                    const Icon(Icons.check_circle,
                        color: NColors.primary, size: 18),
                ]),
              ),
            ),
          ),

          // Photo proof reminder
          NCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Icon(Icons.camera_alt_outlined,
                  color: NColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload photo proof',
                      style: NTextStyles.body(13, weight: FontWeight.w600)),
                  Text('Required within 2 minutes of cancelling',
                      style: NTextStyles.body(11, color: NColors.muted)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 12),

          NPrimaryButton(
            'Submit & Reassign Rider',
            onPressed: selectedReason == null
                ? null
                : () async {
                    Navigator.pop(ctx);
                    setState(() => _busy = true);
                    try {
                      await ApiService.instance.driverEmergencyCancel(
                        t.id, _driverId, photoProof: true,
                      );
                      _timer?.cancel();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Emergency cancel submitted. Rider is being reassigned.'),
                            backgroundColor: NColors.surface,
                          ),
                        );
                        context.go('/driver/home');
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()),
                            backgroundColor: NColors.surface));
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
          ),
        ]),
      )),
    );
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = _trip;

    // No active trip
    if (t == null) {
      return Scaffold(
        backgroundColor: NColors.secondary,
        appBar: AppBar(
          title: Text('Active Ride', style: NTextStyles.display(18))),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.directions_car_outlined,
                color: NColors.muted, size: 56),
            const SizedBox(height: 16),
            Text('No ride assigned yet',
                style: NTextStyles.display(18)),
            const SizedBox(height: 8),
            Text(
              'Go online from the Home tab.\nThe round-robin engine will assign your next ride automatically.',
              textAlign: TextAlign.center,
              style: NTextStyles.body(13, color: NColors.muted),
            ),
            const SizedBox(height: 24),
            NPrimaryButton(
              'Go to Home',
              onPressed: () => context.go('/driver/home'),
            ),
          ]),
        )),
        bottomNavigationBar: _buildBottomNav(1),
      );
    }

    // Active trip
    String titleText, subText;
    if (t.isAssigned) {
      titleText = 'Heading to pickup';
      subText = 'Navigate to pickup location';
    } else if (t.isArrived) {
      titleText = 'Arrived at pickup';
      subText = 'Waiting for rider — max 5 minutes';
    } else if (t.isInProgress) {
      titleText = 'Trip in progress';
      subText = 'Navigate to drop location';
    } else if (t.isCompleted) {
      titleText = 'Trip complete!';
      subText = 'Returning to home…';
    } else {
      titleText = t.status;
      subText = '';
    }

    return Scaffold(
      backgroundColor: NColors.secondary,
      appBar: AppBar(title: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titleText, style: NTextStyles.display(16)),
        if (subText.isNotEmpty)
          Text(subText, style: NTextStyles.body(11, color: NColors.muted)),
      ])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          NMapPlaceholder(height: t.isArrived ? 140 : 220),
          const SizedBox(height: 12),

          // Trip details card
          NCard(child: Column(children: [
            _Row('Pickup',
                t.pickupLabel.isNotEmpty ? t.pickupLabel : 'Pickup location'),
            const SizedBox(height: 6),
            _Row('Drop',
                t.dropLabel.isNotEmpty ? t.dropLabel : 'Drop location'),
            const SizedBox(height: 6),
            _Row('Fare', '₹${t.lockedFare}',
                valueColor: NColors.primary),
            const SizedBox(height: 6),
            _Row('Vehicle', t.vehicleType),
          ])),
          const SizedBox(height: 16),

          // Action buttons based on status
          if (t.isAssigned) ...[
            NPrimaryButton(
              'Mark Arrived at Pickup',
              loading: _busy,
              onPressed: _busy
                  ? null
                  : () => _act(() => ApiService.instance.driverArrived(t.id)),
            ),
            const SizedBox(height: 10),
            NSecondaryButton(
              'Emergency Cancel',
              icon: Icon(Icons.warning_amber_outlined,
                  color: NColors.primary, size: 16),
              onPressed: _busy ? null : _showEmergencySheet,
            ),
          ],

          if (t.isArrived) ...[
            NPrimaryButton(
              'Start Trip',
              loading: _busy,
              onPressed: _busy
                  ? null
                  : () => _act(() => ApiService.instance.startTrip(t.id)),
            ),
            const SizedBox(height: 10),
            NSecondaryButton(
              'Rider No Show',
              onPressed: _busy ? null : _noShow,
            ),
          ],

          if (t.isInProgress) ...[
            Center(child: NPriceBadge(
                amount: t.lockedFare, label: 'FARE')),
            const SizedBox(height: 16),
            NPrimaryButton(
              'Complete Ride',
              loading: _busy,
              onPressed: _busy
                  ? null
                  : () => _act(() => ApiService.instance.completeTrip(t.id)),
            ),
            const SizedBox(height: 10),
            NSecondaryButton(
              'Emergency Cancel',
              icon: Icon(Icons.warning_amber_outlined,
                  color: NColors.primary, size: 16),
              onPressed: _busy ? null : _showEmergencySheet,
            ),
          ],

          if (t.isCompleted) ...[
            const SizedBox(height: 20),
            const Icon(Icons.check_circle,
                color: NColors.primary, size: 56),
            const SizedBox(height: 8),
            Text('Trip complete!', style: NTextStyles.display(20)),
            const SizedBox(height: 8),
            Text('+₹${t.lockedFare}', style: NTextStyles.mono(32)),
            const SizedBox(height: 4),
            Text('Credited within 15 minutes',
                style: NTextStyles.body(12, color: NColors.muted)),
          ],
        ]),
      ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }

  BottomNavigationBar _buildBottomNav(int index) => BottomNavigationBar(
    currentIndex: index,
    onTap: (i) {
      if (i == 0) context.go('/driver/home');
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
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: NTextStyles.body(13, color: NColors.muted)),
      Text(value,
          style: NTextStyles.body(13,
              color: valueColor ?? NColors.white,
              weight: valueColor != null ? FontWeight.w600 : FontWeight.w400)),
    ],
  );
}
