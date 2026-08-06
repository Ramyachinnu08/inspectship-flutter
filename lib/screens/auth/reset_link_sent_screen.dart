import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '_auth_shell.dart';
import 'set_new_password_screen.dart';

class ResetLinkSentScreen extends StatelessWidget {
  const ResetLinkSentScreen({super.key});

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
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              'If an account exists, you will receive a reset link.',
              style: TextStyle(
                  fontSize: 14, color: AppColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 6),
            Text('Check your email for the reset link.',
                style: TextStyle(
                    fontSize: 14, color: AppColors.inkSoft, height: 1.5)),
            const SizedBox(height: 22),
            OutlinedNavyButton(
              label: 'Back to Sign In',
              onPressed: () => Navigator.of(context)
                  .popUntil((r) => r.isFirst),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const SetNewPasswordScreen())),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.inkSoft,
                    textStyle: const TextStyle(fontSize: 12)),
                child: const Text('(demo) open Set New Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}