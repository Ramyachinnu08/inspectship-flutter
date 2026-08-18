import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../api_service.dart';
import '_auth_shell.dart';
import 'reset_link_sent_screen.dart';

const _kOrange = Color(0xFFE8630A);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _send() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final result = await ApiService.forgotPassword(_email.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      // extract token from reset_link if email not configured
      String? token;
      final link = result['reset_link']?.toString();
      if (link != null && link.isNotEmpty) {
        token = Uri.tryParse(link)?.queryParameters['token'];
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResetLinkSentScreen(token: token)),
      );
    } else {
      setState(() => _error = result['message']?.toString() ?? 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Forgot Password',
      subtitle: 'Inspector Portal',
      card: AuthCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Reset your password',
                style: TextStyle(
                    fontFamily: 'Georgia',
                    fontFamilyFallback: ['Times New Roman', 'serif'],
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2A44))),
            const SizedBox(height: 6),
            Text('Enter your email to receive a reset link.',
                style: TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.4)),
            const SizedBox(height: 22),
            const Text('Email',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF374151))),
            const SizedBox(height: 7),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email address',
                prefixIcon: const Icon(Icons.mail_outline, color: _kOrange, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF3C9A8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF3C9A8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kOrange, width: 1.5),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
            ],
            const SizedBox(height: 20),
            NavyButton(label: 'Send Reset Link', onPressed: _send, loading: _loading),
            const SizedBox(height: 18),
            // ── OR divider ──
            Row(
              children: [
                Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('OR',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF))),
                ),
                Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 18, color: _kOrange),
                label: const Text('Back to Sign In'),
                style: TextButton.styleFrom(
                    foregroundColor: _kOrange,
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}