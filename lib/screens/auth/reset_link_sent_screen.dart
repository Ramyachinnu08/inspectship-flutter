import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '_auth_shell.dart';
import 'set_new_password_screen.dart';

class ResetLinkSentScreen extends StatelessWidget {
  final String? token;
  const ResetLinkSentScreen({super.key, this.token});

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
            const SizedBox(height: 10),
            Text(
              'If an account exists, you will receive a reset link.',
              style: TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 6),
            Text('Check your email for the reset link.',
                style: TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.5)),
            const SizedBox(height: 22),
            // If email is not configured, backend returned a token → allow continue
            if (token != null && token!.isNotEmpty)
              NavyButton(
                label: 'Continue to Reset',
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => SetNewPasswordScreen(token: token!))),
              ),
            if (token != null && token!.isNotEmpty) const SizedBox(height: 10),
            OutlinedNavyButton(
              label: 'Back to Sign In',
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}