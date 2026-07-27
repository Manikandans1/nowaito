import 'package:flutter/material.dart';
import '../theme/tokens.dart';

// ── NCard ─────────────────────────────────────────────────────────────────────
class NCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Border? border;

  const NCard({super.key, required this.child, this.padding, this.color, this.border});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color ?? NColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: border ?? Border.all(color: NColors.muted.withValues(alpha: 0.15)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14, offset: const Offset(0, 3)),
      ],
    ),
    child: child,
  );
}

// ── NPill ─────────────────────────────────────────────────────────────────────
class NPill extends StatelessWidget {
  final String text;
  final bool primary;
  const NPill(this.text, {super.key, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final color  = primary ? NColors.primary : NColors.white;
    final bg     = primary ? NColors.primary.withValues(alpha: 0.12) : NColors.muted.withValues(alpha: 0.15);
    final border = primary ? NColors.primary.withValues(alpha: 0.5)  : NColors.muted.withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(text, style: NTextStyles.body(11, color: color, weight: FontWeight.w500)),
    );
  }
}

// ── NPrimaryButton ────────────────────────────────────────────────────────────
class NPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  const NPrimaryButton(this.label, {super.key, this.onPressed,
      this.loading = false, this.fullWidth = true});

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: NColors.secondary, strokeWidth: 2))
          : Text(label),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// ── NSecondaryButton ──────────────────────────────────────────────────────────
class NSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  const NSecondaryButton(this.label,
      {super.key, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon ?? const SizedBox.shrink(),
      label: Text(label),
    ),
  );
}

// ── NPriceBadge ───────────────────────────────────────────────────────────────
class NPriceBadge extends StatelessWidget {
  final int amount;
  final String label;
  final bool large;
  const NPriceBadge({super.key, required this.amount,
      this.label = 'LOCKED', this.large = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12, vertical: large ? 10 : 6),
    decoration: BoxDecoration(
      color: NColors.surface,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: NColors.primary),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.lock_outline, color: NColors.primary,
          size: large ? 16 : 12),
      const SizedBox(width: 6),
      Text('₹$amount', style: NTextStyles.mono(
          large ? 22 : 13, color: NColors.white)),
      const SizedBox(width: 6),
      Text(label, style: NTextStyles.mono(large ? 11 : 9)
          .copyWith(letterSpacing: 1)),
    ]),
  );
}

// ── NRowItem ─────────────────────────────────────────────────────────────────
class NRowItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const NRowItem({super.key, required this.icon, required this.title,
      this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: NColors.muted.withValues(alpha: 0.12)))),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: NColors.secondary, shape: BoxShape.circle,
            border: Border.all(color: NColors.muted.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: NColors.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: NTextStyles.body(14, weight: FontWeight.w500)),
          if (subtitle != null)
            Text(subtitle!, style: NTextStyles.body(12, color: NColors.muted)),
        ])),
        trailing ?? Icon(Icons.chevron_right, color: NColors.muted, size: 18),
      ]),
    ),
  );
}

// ── NMapPlaceholder ───────────────────────────────────────────────────────────
class NMapPlaceholder extends StatelessWidget {
  final double height;
  final String zone;
  const NMapPlaceholder({super.key, this.height = 150,
      this.zone = 'KORAMANGALA'});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      color: NColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: NColors.muted.withValues(alpha: 0.2)),
    ),
    child: CustomPaint(
      painter: _GridPainter(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('ZONE: $zone',
                style: NTextStyles.mono(9, color: NColors.primary)),
          ),
        ),
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gp = Paint()
      ..color = NColors.muted.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    final rp = Paint()
      ..color = NColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final dp = Paint()..color = NColors.primary;

    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gp);
    }
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.82)
      ..cubicTo(size.width * 0.3, size.height * 0.28,
          size.width * 0.52, size.height * 0.5,
          size.width * 0.9, size.height * 0.18);
    canvas.drawPath(path, rp);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.82), 5, dp);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.18), 5,
        Paint()..color = NColors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.18), 5,
        Paint()..color = NColors.primary..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ── NSegmentedTab ─────────────────────────────────────────────────────────────
class NSegmentedTab extends StatelessWidget {
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  const NSegmentedTab({super.key, required this.options,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: NColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: NColors.muted.withValues(alpha: 0.3)),
    ),
    child: Row(children: options.map((o) {
      final active = o == value;
      return Expanded(child: GestureDetector(
        onTap: () => onChanged(o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? NColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(o,
            textAlign: TextAlign.center,
            style: NTextStyles.body(12,
              color: active ? NColors.secondary : NColors.muted,
              weight: FontWeight.w600),
          ),
        ),
      ));
    }).toList()),
  );
}
