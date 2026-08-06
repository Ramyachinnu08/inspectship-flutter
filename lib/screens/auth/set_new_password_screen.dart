import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '_auth_shell.dart';
import 'password_updated_screen.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});
  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _pw = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  bool get _len => _pw.text.length >= 8;
  bool get _upper => _pw.text.contains(RegExp(r'[A-Z]'));
  bool get _lower => _pw.text.contains(RegExp(r'[a-z]'));
  bool get _num => _pw.text.contains(RegExp(r'\d'));
  bool get _special =>
      _pw.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\;\[\]]'));
  bool get _valid => _len && _upper && _lower && _num && _special;

  Future<void> _submit() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PasswordUpdatedScreen()),
    );
  }

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
            const SizedBox(height: 6),
            Text('Enter your new password.',
                style: TextStyle(
                    fontSize: 14, color: AppColors.inkSoft, height: 1.4)),
            const SizedBox(height: 22),
            const Text('New password',
                style:
                TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _pw,
              obscureText: _obscure,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter new password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _rule('8+ characters', _len),
            _rule('Uppercase letter', _upper),
            _rule('Lowercase letter', _lower),
            _rule('Number', _num),
            _rule('Special character', _special),
            const SizedBox(height: 20),
            NavyButton(
              label: 'Update Password',
              onPressed: _valid ? _submit : null,
              loading: _loading,
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((r) => r.isFirst),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.signal,
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                child: const Text('Back to Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rule(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16, color: ok ? AppColors.pass : AppColors.inkSoft),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: ok ? AppColors.ink : AppColors.inkSoft)),
        ],
      ),
    );
  }
}