import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget card;
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandBadge(),
                  const SizedBox(height: 22),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .55),
                          fontSize: 14)),
                  const SizedBox(height: 26),
                  card,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF15305A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.signal,
          borderRadius: BorderRadius.circular(14),
        ),
        child: CustomPaint(
          painter: _ShipInspectorLogo(),
        ),
      ),
    );
  }
}

class _ShipInspectorLogo extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final stroke = Paint()
      ..color = Colors.white
      ..strokeWidth = w * .055
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = Colors.white;

    final eyeTop = h * .18;
    final eyePath = Path()
      ..moveTo(cx - w * .18, eyeTop + h * .04)
      ..quadraticBezierTo(cx, eyeTop - h * .05, cx + w * .18, eyeTop + h * .04)
      ..quadraticBezierTo(cx, eyeTop + h * .12, cx - w * .18, eyeTop + h * .04)
      ..close();
    canvas.drawPath(eyePath, stroke);
    canvas.drawCircle(Offset(cx, eyeTop + h * .04), w * .045, fill);

    canvas.drawLine(
      Offset(cx, eyeTop + h * .13),
      Offset(cx, h * .82),
      stroke,
    );

    canvas.drawLine(
      Offset(cx - w * .12, h * .40),
      Offset(cx + w * .12, h * .40),
      stroke,
    );
    canvas.drawLine(
      Offset(cx - w * .18, h * .52),
      Offset(cx + w * .18, h * .52),
      stroke,
    );

    final left = Path()
      ..moveTo(cx - w * .28, h * .82)
      ..quadraticBezierTo(cx - w * .32, h * .68, cx - w * .10, h * .68);
    final right = Path()
      ..moveTo(cx + w * .28, h * .82)
      ..quadraticBezierTo(cx + w * .32, h * .68, cx + w * .10, h * .68);
    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);

    canvas.drawLine(
      Offset(cx - w * .28, h * .82),
      Offset(cx + w * .28, h * .82),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class NavyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const NavyButton(
      {super.key, required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: loading
          ? const SizedBox(
          width: 22,
          height: 22,
          child:
          CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label),
    );
  }
}

class OutlinedNavyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const OutlinedNavyButton(
      {super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}