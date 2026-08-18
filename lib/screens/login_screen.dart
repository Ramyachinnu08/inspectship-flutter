import 'package:flutter/material.dart';
import '../api_service.dart';
import 'main_shell.dart';
import 'auth/forgot_password_screen.dart';

// ===== RightKnot maritime palette (matches mockup) =====
const _kBgTop = Color(0xFF241008);      // deep dark brown (top)
const _kBgMid = Color(0xFF4A2410);      // warm mid brown
const _kBgBottom = Color(0xFF7A3A12);   // burnt orange glow (bottom)
const _kCream = Color(0xFFFAF3E7);      // card background
const _kCreamField = Color(0xFFFDF9F0); // input fill
const _kFieldBorder = Color(0xFFE3D3B8);
const _kBrown = Color(0xFF5C2E0E);      // headings
const _kBrownSoft = Color(0xFF8A6A4E);  // subtitle text
const _kOrange = Color(0xFFC2551B);     // button top
const _kOrangeDeep = Color(0xFFA23E0E); // button bottom
const _kGoldLine = Color(0xFFB97A3C);   // divider lines
const _kFooterTan = Color(0xFFC98A4B);  // footer text

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

  InputDecoration _fieldDecoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA89880), fontSize: 15),
      prefixIcon: Icon(icon, size: 20, color: _kBrownSoft),
      suffixIcon: suffix,
      filled: true,
      fillColor: _kCreamField,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kFieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kFieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kOrange, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Ship photo background (original image, no filter)
        color: _kBgTop, // fallback color while image loads
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://i.ibb.co/LzgNFxzM/login.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== Logo in cream frame =====
                      Container(
                        width: 96,
                        height: 62,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _kCream,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kGoldLine.withOpacity(0.6)),
                          boxShadow: [
                            BoxShadow(
                              color: _kOrange.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.network(
                          'https://i.ibb.co/8g7pqvvr/knot.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.directions_boat, color: _kOrange, size: 32),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ===== RIGHTKNOT serif title =====
                      const Text(
                        'RIGHTKNOT',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: ['Times New Roman', 'serif'],
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF5EBDD),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ===== Subtitle with decorative lines =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 46, height: 1, color: _kGoldLine),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Vessel Inspection Platform',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontFamilyFallback: ['Times New Roman', 'serif'],
                                fontSize: 15,
                                color: Color(0xFFE0A868),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(width: 46, height: 1, color: _kGoldLine),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // ===== Cream login card =====
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: _kCream,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontFamilyFallback: ['Times New Roman', 'serif'],
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: _kBrown,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sign in to continue your inspections',
                              style: TextStyle(fontSize: 14.5, color: _kBrownSoft),
                            ),
                            const SizedBox(height: 26),

                            // Email
                            const Text('Email',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3D2817))),
                            const SizedBox(height: 7),
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Color(0xFF3D2817)),
                              decoration: _fieldDecoration(
                                hint: 'you@company.com',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Password
                            const Text('Password',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3D2817))),
                            const SizedBox(height: 7),
                            TextField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              onSubmitted: (_) => _login(),
                              style: const TextStyle(color: Color(0xFF3D2817)),
                              decoration: _fieldDecoration(
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: _kBrownSoft,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDECEC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFF0C4C4)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.error_outline,
                                      color: Color(0xFFC0392B), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(_error!,
                                          style: const TextStyle(
                                              color: Color(0xFFC0392B), fontSize: 13))),
                                ]),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // ===== Gradient Sign In button with ship's wheel =====
                            Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [_kOrange, _kOrangeDeep],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kOrangeDeep.withOpacity(0.45),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _loading ? null : _login,
                                  child: Center(
                                    child: _loading
                                        ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white))
                                        : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('☸',
                                            style: TextStyle(
                                                fontSize: 20, color: Colors.white)),
                                        SizedBox(width: 10),
                                        Text('Sign In',
                                            style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: const Text('Forgot password?',
                                    style: TextStyle(
                                        color: Color(0xFFA34A16),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ===== Footer with anchor =====
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.anchor, size: 15, color: _kFooterTan),
                          SizedBox(width: 7),
                          Text('© 2026 RightKnot Shipping',
                              style: TextStyle(fontSize: 13, color: _kFooterTan)),
                        ],
                      ),
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}