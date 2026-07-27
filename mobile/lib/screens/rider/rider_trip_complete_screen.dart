import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

class RiderTripCompleteScreen extends StatefulWidget {
  final String tripId;
  final String vehicle;
  const RiderTripCompleteScreen({
    super.key, required this.tripId, required this.vehicle,
  });
  @override
  State<RiderTripCompleteScreen> createState() =>
      _RiderTripCompleteScreenState();
}

class _RiderTripCompleteScreenState extends State<RiderTripCompleteScreen> {
  Trip? _trip;
  Driver? _driver;
  int _rating = 0;
  bool _submitted = false;
  bool _safetyCheckSent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await ApiService.instance.getTrip(widget.tripId);
      if (!mounted) return;
      setState(() => _trip = t);

      // Fetch real driver name for rating
      if (t.driverId != null) {
        try {
          final d = await ApiService.instance.getDriver(t.driverId!);
          if (mounted) setState(() => _driver = d);
        } catch (_) {}
      }

      // Send safety check notification 5 seconds after screen loads
      Timer(const Duration(seconds: 5), () {
        if (mounted && !_safetyCheckSent) {
          _safetyCheckSent = true;
          NotificationService.instance.safetyCheck();
          _showSafetyModal();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load trip: ${e.toString()}'),
          backgroundColor: NColors.surface,
        ),
      );
    }
  }

  void _showSafetyModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isDismissible: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified_user, color: NColors.primary, size: 44),
          const SizedBox(height: 12),
          Text('Did you arrive safely?',
              style: NTextStyles.display(18),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'Your safety is our top priority.',
            style: NTextStyles.body(13, color: NColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: NPrimaryButton(
              "Yes, I'm safe",
              onPressed: () => Navigator.pop(context),
            )),
            const SizedBox(width: 12),
            Expanded(child: NSecondaryButton(
              'Report issue',
              onPressed: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            )),
          ]),
        ]),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: NColors.surface,
        title: Text('Report an issue', style: NTextStyles.display(16)),
        content: Text(
          'Please contact NoWaito support at support@nowaito.in with your Trip ID:\n\n${widget.tripId}',
          style: NTextStyles.body(13, color: NColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: NColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _trip;
    if (t == null) {
      return const Scaffold(
        backgroundColor: NColors.secondary,
        body: Center(child: CircularProgressIndicator(color: NColors.primary)),
      );
    }

    final driverName = _driver?.name ?? 'your driver';

    return Scaffold(
      backgroundColor: NColors.secondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.check_circle, color: NColors.primary, size: 56),
              const SizedBox(height: 16),
              Text("You've arrived!", style: NTextStyles.display(24)),
              const SizedBox(height: 4),
              Text(
                'Thank you for riding with NoWaito',
                style: NTextStyles.body(13, color: NColors.muted),
              ),
              const SizedBox(height: 24),

              // Receipt card
              NCard(child: Column(children: [
                _Row('Ride fare', '₹${t.lockedFare}'),
                const SizedBox(height: 6),
                _Row('Guarantee fee', '₹${t.guaranteeFee}'),
                const SizedBox(height: 8),
                const Divider(color: NColors.muted, height: 1),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Text('Total charged',
                      style: NTextStyles.body(14,
                          weight: FontWeight.w600)),
                  Text('₹${t.total}',
                      style: NTextStyles.mono(16,
                          color: NColors.primary)),
                ]),
              ])),
              const SizedBox(height: 8),
              Text(
                '₹${t.total} was reserved at booking — now confirmed and charged automatically. No cash needed.',
                textAlign: TextAlign.center,
                style: NTextStyles.body(11, color: NColors.muted),
              ),
              const SizedBox(height: 28),

              // Star rating — real interaction
              Text(
                'Rate $driverName',
                style: NTextStyles.body(14, color: NColors.muted),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) =>
                GestureDetector(
                  onTap: _submitted
                      ? null
                      : () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: NColors.primary,
                      size: 32,
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 6),
              if (_rating == 0)
                Text('Tap a star to rate',
                    style: NTextStyles.body(11, color: NColors.muted)),
              const SizedBox(height: 24),

              if (!_submitted)
                NPrimaryButton(
                  _rating == 0 ? 'Skip & go home' : 'Submit rating',
                  onPressed: () {
                    setState(() => _submitted = true);
                    context.go('/rider/home');
                  },
                )
              else
                const CircularProgressIndicator(color: NColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: NTextStyles.body(13, color: NColors.muted)),
      Text(value, style: NTextStyles.body(13)),
    ],
  );
}
