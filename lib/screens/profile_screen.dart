import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../api_service.dart';
import '../offline_store.dart';
import 'login_screen.dart';

const _kPrimary = Color(0xFFF06B26);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _online = true;
  int _pendingSync = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser();
    final online = await OfflineStore.instance.isOnline();
    setState(() {
      _user = user;
      _online = online;
      _pendingSync = OfflineStore.instance.pendingSyncCount;
      _loading = false;
    });
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _changePassword() async {
    final online = await OfflineStore.instance.isOnline();
    if (!online) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password change requires an internet connection.')),
      );
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => const _ChangePasswordDialog(),
    );
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear offline cache'),
        content: Text(_pendingSync > 0
            ? 'You have $_pendingSync inspection(s) not yet synced. Clearing will DELETE them permanently. Continue?'
            : 'This clears cached assignments and inspection drafts stored on this device. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await OfflineStore.instance.clearAll();
    if (!mounted) return;
    setState(() => _pendingSync = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Offline cache cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.of(context).maybePop()),
        title: Row(children: [
          Container(width: 32, height: 32, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)), child: Image.network('https://i.ibb.co/8g7pqvvr/knot.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(color: _kPrimary, child: const Icon(Icons.directions_boat, color: Colors.white, size: 20)))),
          const SizedBox(width: 8),
          const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Inspector Profile
                _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: const [Icon(Icons.person_outline, color: Colors.black, size: 20), SizedBox(width: 8), Text('Inspector Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black))]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Container(width: 56, height: 56, decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle), child: const Icon(Icons.person, color: Color(0xFF6B7280), size: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_user?['name'] ?? 'Unknown', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black)),
                      const SizedBox(height: 2),
                      Text(_user?['email'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                      const SizedBox(height: 4),
                      Text((_user?['role'] ?? 'inspector').toString().replaceAll('_', ' '), style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    ])),
                  ]),
                ])),
                const SizedBox(height: 16),
                // Security
                _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: const [Icon(Icons.key_outlined, color: Colors.black, size: 20), SizedBox(width: 8), Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black))]),
                  const SizedBox(height: 6),
                  const Text('Change your account password. Requires internet connection.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: _changePassword,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), side: const BorderSide(color: Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Change password', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ])),
                const SizedBox(height: 16),
                // Device Info
                _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: const [Icon(Icons.smartphone_outlined, color: Colors.black, size: 20), SizedBox(width: 8), Text('Device Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black))]),
                  const SizedBox(height: 14),
                  _kvRow('Platform', kIsWeb ? 'Web' : 'Mobile App'),
                  const SizedBox(height: 10),
                  _kvRow('Connection', _online ? 'Online' : 'Offline'),
                  const SizedBox(height: 10),
                  _kvRow('Pending sync', '$_pendingSync inspection(s)'),
                ])),
                const SizedBox(height: 16),
                // Offline Storage
                _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: const [Icon(Icons.storage_outlined, color: Colors.black, size: 20), SizedBox(width: 8), Text('Offline Storage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black))]),
                  const SizedBox(height: 6),
                  const Text('Cached assignments + inspection drafts stored on this device.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    onPressed: _clearCache,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                    child: const Text('Clear offline cache', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  )),
                ])),
                const SizedBox(height: 16),
                // Sign Out
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Sign Out', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
    child: child,
  );

  Widget _kvRow(String k, String v) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(k, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
    Text(v, style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600)),
  ]);
}

// ─── Change Password Dialog ─────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_oldCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'New passwords do not match');
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters');
      return;
    }
    setState(() => _busy = true);
    final result = await ApiService.changePassword(_oldCtrl.text, _newCtrl.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully'), backgroundColor: Color(0xFF22C55E)),
      );
    } else {
      setState(() => _error = result['message']?.toString() ?? 'Failed to change password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
          const SizedBox(height: 10),
          TextField(controller: _newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 10),
          TextField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Update'),
        ),
      ],
    );
  }
}