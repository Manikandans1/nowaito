import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

class RiderActiveTripScreen extends StatefulWidget {
  final String tripId;
  final String vehicle;
  const RiderActiveTripScreen({
    super.key, required this.tripId, required this.vehicle,
  });
  @override
  State<RiderActiveTripScreen> createState() => _RiderActiveTripScreenState();
}

class _RiderActiveTripScreenState extends State<RiderActiveTripScreen> {
  Trip? _trip;
  Driver? _driver;
  Timer? _timer;
  bool _cancelling = false;
  String? _prevStatus;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final t = await ApiService.instance.getTrip(widget.tripId);
      if (!mounted) return;

      // Fire in-app notifications when status changes
      if (t.status != _prevStatus) {
        _onStatusChange(t);
        _prevStatus = t.status;
      }

      // Fetch real driver details when assigned
      if (t.driverId != null && _driver == null) {
        try {
          final d = await ApiService.instance.getDriver(t.driverId!);
          if (mounted) setState(() => _driver = d);
        } catch (_) {}
      }

      setState(() => _trip = t);

      if (t.isCompleted) {
        _timer?.cancel();
        if (!mounted) return;
        context.go('/rider/trip-complete',
            extra: {'tripId': widget.tripId, 'vehicle': widget.vehicle});
      }

      if (t.isCancelled) {
        _timer?.cancel();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your ride was cancelled. Please book again.'),
          backgroundColor: NColors.surface,
        ));
        context.go('/rider/home');
      }
    } catch (_) {}
  }

  void _onStatusChange(Trip t) {
    switch (t.status) {
      case 'DRIVER_ASSIGNED':
        NotificationService.instance.driverAssigned(
          _driver?.name ?? 'Your driver',
          _driver?.vehicleLabel ?? widget.vehicle,
          '4 min',
        );
        break;
      case 'ARRIVED':
        NotificationService.instance.driverArrived();
        break;
      case 'IN_PROGRESS':
        NotificationService.instance.tripStarted();
        break;
      case 'COMPLETED':
        NotificationService.instance.tripComplete(_trip?.total ?? 0);
        break;
    }
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ApiService.instance.riderCancel(widget.tripId);
      _timer?.cancel();
      if (!mounted) return;
      context.go('/rider/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: NColors.surface));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _launchSOS() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not launch phone dialer'),
        backgroundColor: NColors.surface,
      ));
    }
  }

  Future<void> _shareTrip() async {
    final t = _trip;
    if (t == null) return;
    final d = _driver;
    final text =
        'I am riding with NoWaito.\n'
        'Driver: ${d?.name ?? "Assigned"}\n'
        'Vehicle: ${d?.vehicleLabel ?? widget.vehicle} · ${d?.plateNumber ?? ""}\n'
        'Trip ID: ${t.id}\n'
        'Track my trip in the NoWaito app.';
    final uri = Uri(
      scheme: 'whatsapp',
      path: 'send',
      queryParameters: {'text': text},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback to plain share
      final smsUri = Uri(scheme: 'sms', queryParameters: {'body': text});
      await launchUrl(smsUri);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _trip;
    final d = _driver;

    if (t == null) {
      return const Scaffold(
        backgroundColor: NColors.secondary,
        body: Center(child: CircularProgressIndicator(color: NColors.primary)),
      );
    }

    String title, subtitle;
    if (t.isSearching) {
      title = 'Finding your driver';
      subtitle = 'Round-robin queue — instant';
    } else if (t.isAssigned) {
      title = 'Driver assigned';
      subtitle = 'Arriving in ~4 min';
    } else if (t.isArrived) {
      title = 'Driver has arrived';
      subtitle = 'Please board now';
    } else {
      title = 'On the way';
      subtitle = 'Trip in progress';
    }

    return Scaffold(
      backgroundColor: NColors.secondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: NTextStyles.display(16)),
          Text(subtitle, style: NTextStyles.body(11, color: NColors.muted)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Finding state
          if (t.isSearching) ...[
            const SizedBox(height: 40),
            Center(child: Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NColors.primary.withValues(alpha: 0.12),
                border: Border.all(
                    color: NColors.primary.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.bolt, color: NColors.primary, size: 36),
            )),
            const SizedBox(height: 20),
            Text(
              'Assigning your ${widget.vehicle} driver automatically.\nNo wait, no cherry-picking.',
              textAlign: TextAlign.center,
              style: NTextStyles.body(13, color: NColors.muted),
            ),
          ],

          // Assigned / In-progress state
          if (!t.isSearching) ...[
            // Free cancel countdown
            if (t.isAssigned) ...[
              NCard(
                border: Border.all(
                    color: NColors.primary.withValues(alpha: 0.5)),
                child: Row(children: [
                  const Icon(Icons.timer_outlined,
                      color: NColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Free cancellation available for 3 minutes',
                    style: NTextStyles.body(12),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            const NMapPlaceholder(height: 200),
            const SizedBox(height: 12),

            // Driver card — shows REAL driver data from API
            NCard(child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: NColors.muted.withValues(alpha: 0.3),
                child: Text(
                  d != null ? d.name[0].toUpperCase() : '?',
                  style: NTextStyles.display(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d?.name ?? 'Assigning driver…',
                    style: NTextStyles.body(14, weight: FontWeight.w600),
                  ),
                  Text(
                    d != null
                        ? '${d.vehicleLabel} · ${d.plateNumber}'
                        : widget.vehicle,
                    style: NTextStyles.body(12, color: NColors.muted),
                  ),
                ],
              )),
              Row(children: [
                const Icon(Icons.star, color: NColors.primary, size: 14),
                const SizedBox(width: 2),
                Text('4.8', style: NTextStyles.mono(12, color: NColors.white)),
              ]),
            ])),
            const SizedBox(height: 12),

            // Action buttons — all wired
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.phone_outlined, size: 16),
                label: const Text('Call'),
                onPressed: d == null
                    ? null
                    : () async {
                        final uri = Uri(scheme: 'tel', path: d.plateNumber);
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Share'),
                onPressed: _shareTrip,
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700),
                icon: const Icon(Icons.sos, size: 16),
                label: const Text('SOS'),
                onPressed: _launchSOS,
              )),
            ]),
            const SizedBox(height: 12),

            // Verify before boarding
            if (t.isAssigned || t.isArrived)
              NCard(child: Row(children: [
                const Icon(Icons.verified_user_outlined,
                    color: NColors.primary, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Verify driver name, photo & plate number before boarding',
                    style: TextStyle(color: NColors.muted, fontSize: 12),
                  ),
                ),
              ])),

            // Price lock
            if (!t.isSearching) ...[
              const SizedBox(height: 16),
              Center(child: NPriceBadge(
                  amount: t.total, label: 'FINAL')),
            ],

            const SizedBox(height: 20),

            // Cancel — only before trip starts
            if (!t.isInProgress && !t.isCompleted)
              NSecondaryButton(
                'Cancel ride',
                onPressed: _cancelling ? null : _cancel,
              ),
          ],
        ]),
      ),
    );
  }
}
