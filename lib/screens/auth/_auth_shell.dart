import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ===== RightKnot maritime palette =====
const _kOrange = Color(0xFFE8630A);
const _kOrangeDeep = Color(0xFFC24E08);
const _kTitle = Color(0xFF1F2A44); // dark title over bright sky
const _kSub = Color(0xFF4A5568);

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
      body: Container(
        color: const Color(0xFF241008),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://i.ibb.co/KpdYY289/forgetten.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandBadge(),
                      const SizedBox(height: 20),
                      Text(title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontFamilyFallback: [
                                'Times New Roman',
                                'serif'
                              ],
                              color: _kTitle,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .2)),
                      const SizedBox(height: 8),
                      // "• Inspector Portal •" with orange dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.circle, size: 6, color: _kOrange),
                          const SizedBox(width: 10),
                          Text(subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: _kSub,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                          const Icon(Icons.circle, size: 6, color: _kOrange),
                        ],
                      ),
                      const SizedBox(height: 26),
                      card,
                    ],
                  ),
                ),
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
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kOrange, width: 2),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.network(
        'https://i.ibb.co/8g7pqvvr/knot.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.anchor, color: _kOrange, size: 40),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
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
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF08A3C), _kOrange, _kOrangeDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: _kOrangeDeep.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onPressed,
          child: Center(
            child: loading
                ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(width: 10),
                const Icon(Icons.send, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
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
        foregroundColor: _kOrange,
        side: const BorderSide(color: _kOrange, width: 1.3),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}