import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../api_service.dart';
import '_auth_shell.dart';
import 'reset_link_sent_screen.dart';

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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Enter your email to receive a reset link.',
                style: TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.4)),
            const SizedBox(height: 22),
            const Text('Email',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
            ],
            const SizedBox(height: 20),
            NavyButton(label: 'Send Reset Link', onPressed: _send, loading: _loading),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.signal,
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                child: const Text('Back to Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}