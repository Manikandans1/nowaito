import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/session_provider.dart';
import '../theme/tokens.dart';
import '../widgets/widgets.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NColors.secondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Spacer(),
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(color: NColors.primary, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.bolt, color: NColors.secondary, size: 36),
            ),
            const SizedBox(height: 20),
            Text("NoWaito", style: NTextStyles.display(44, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text("Ride Guaranteed.", style: NTextStyles.body(14, color: NColors.primary).copyWith(letterSpacing: 3)),
            const SizedBox(height: 8),
            Text("Zone-based · Price-locked · Always Complete",
                style: NTextStyles.body(12, color: NColors.muted), textAlign: TextAlign.center),
            const Spacer(),
            NPrimaryButton("Continue as Rider", onPressed: () => context.go("/rider-login")),
            const SizedBox(height: 12),
            NSecondaryButton("Continue as Driver", onPressed: () => context.go("/driver-login")),
            const SizedBox(height: 24),
            Text("Production ships these as two separate apps from the same codebase.",
                textAlign: TextAlign.center, style: NTextStyles.body(10, color: NColors.muted)),
          ]),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  bool   _otpSent  = false;
  bool   _loading  = false;
  String? _devCode;
  String? _error;

  bool get _isRider => widget.role == "RIDER";

  Future<void> _requestOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) { setState(() => _error = "Enter a valid 10-digit phone number"); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.instance.requestOtp(phone);
      setState(() { _otpSent = true; _devCode = res["devOnlyCode"] as String?; });
    } catch (e) {
      setState(() => _error = "Cannot reach backend. Is it running?\n${e.toString()}");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final code  = _otpCtrl.text.trim();
    if (code.length != 4) { setState(() => _error = "Enter the 4-digit OTP"); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final auth = await ApiService.instance.verifyOtp(phone, code, widget.role);
      await context.read<SessionProvider>().save(auth.token, auth.userId, widget.role);
      if (!mounted) return;
      context.go(_isRider ? "/rider/home" : "/driver/home");
    } catch (e) {
      setState(() => _error = "Invalid OTP. Check backend console for dev OTP code.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _phoneCtrl.dispose(); _otpCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NColors.secondary,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: NColors.white), onPressed: () => context.go("/")),
        title: Text(_isRider ? "Rider Login" : "Driver Login", style: NTextStyles.display(18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            Text(_isRider ? "Where to, today?" : "Keep 100% of your fare.",
                style: NTextStyles.display(26, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(_isRider ? "Enter your phone to continue" : "No commission. Zone Pass model.",
                style: NTextStyles.body(13, color: NColors.muted)),
            const SizedBox(height: 32),

            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: NTextStyles.body(16),
              enabled: !_otpSent,
              decoration: InputDecoration(
                hintText: "Phone number",
                prefixText: "+91 ",
                prefixStyle: NTextStyles.body(16, color: NColors.muted),
                suffixIcon: _otpSent
                    ? GestureDetector(
                        onTap: () => setState(() { _otpSent = false; _devCode = null; _error = null; }),
                        child: const Icon(Icons.edit, color: NColors.primary, size: 18))
                    : null,
              ),
            ),

            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: NTextStyles.mono(28).copyWith(letterSpacing: 12, color: NColors.white),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "----",
                  counterText: "",
                  helperText: _devCode != null ? "Dev OTP (backend console): $_devCode" : null,
                  helperStyle: NTextStyles.body(11, color: NColors.primary),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 10),
              NCard(
                color: NColors.error.withValues(alpha: 0.1),
                border: Border.all(color: NColors.error.withValues(alpha: 0.4)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.error_outline, color: NColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: NTextStyles.body(12, color: NColors.error))),
                ]),
              ),
            ],

            const SizedBox(height: 28),
            NPrimaryButton(
              _otpSent ? "Verify OTP & Continue" : "Send OTP",
              loading: _loading,
              onPressed: _loading ? null : (_otpSent ? _verifyOtp : _requestOtp),
            ),

            if (_isRider) ...[
              const SizedBox(height: 16),
              Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.local_offer_outlined, color: NColors.primary, size: 14),
                const SizedBox(width: 6),
                Text("First ride free — guarantee fee waived",
                    style: NTextStyles.body(12, color: NColors.primary)),
              ])),
            ],
          ]),
        ),
      ),
    );
  }
}
