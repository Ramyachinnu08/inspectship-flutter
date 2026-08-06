import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '_auth_shell.dart';

class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Set New Password',
      subtitle: 'Inspector Portal',
      card: AuthCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Reset password',
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Your password has been updated.',
                style: TextStyle(
                    fontSize: 14, color: AppColors.inkSoft, height: 1.5)),
            const SizedBox(height: 22),
            NavyButton(
              label: 'Sign In',
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}