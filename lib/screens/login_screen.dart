import 'package:flutter/material.dart';
import '../api_service.dart';
import 'main_shell.dart';
import 'auth/forgot_password_screen.dart';

const _kPrimary = Color(0xFFF06B26);
const _kNavy = Color(0xFF1A2A5E);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final result = await ApiService.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    setState(() => _loading = false);
    if (result['success'] == true) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
    } else {
      setState(() => _error = result['message'] ?? 'Login failed');
    }
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Navy gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kNavy, Color(0xFF0F1B3D)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo + brand (above the card)
                    Container(
                      width: 84, height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: _kPrimary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        'https://i.ibb.co/8g7pqvvr/knot.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          color: _kPrimary,
                          child: const Icon(Icons.directions_boat, color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('RIGHTKNOT',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    const Text('Vessel Inspection Platform',
                        style: TextStyle(fontSize: 13, color: Color(0xFFB4C0DA))),
                    const SizedBox(height: 28),

                    // The login CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 12)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome back',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111111))),
                          const SizedBox(height: 4),
                          const Text('Sign in to continue your inspections',
                              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                          const SizedBox(height: 24),

                          // Email
                          const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'you@company.com',
                              prefixIcon: const Icon(Icons.email_outlined, size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            onSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA))),
                              child: Row(children: [
                                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
                              ]),
                            ),
                          ],

                          const SizedBox(height: 22),

                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 52),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text('© 2026 RightKnot Shipping',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8494B4))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}