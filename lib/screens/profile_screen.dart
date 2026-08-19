import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../api_service.dart';
import '../offline_store.dart';
import 'login_screen.dart';

// ===== RightKnots maritime palette =====
const _kTopBar = Color(0xFFFAF3E7);
const _kCard = Color(0xFFFDF8ED);
const _kBrown = Color(0xFF3D2817);
const _kBrownSoft = Color(0xFF8A6A4E);
const _kOrange = Color(0xFFE8630A);
const _kOrangeChip = Color(0xFFF7E3D2);
const _kGreen = Color(0xFF4C7A3C);

// ⬇️⬇️ PROFILE BACKGROUND IMAGE — send me the ibb link and I'll swap it ⬇️⬇️
const _kBgImage = 'https://i.ibb.co/S71jfJ66/vecteezy-ai-generated-large-boat-floating-on-top-of-a-body-of-water-40265161.jpg';

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
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: _kBrown)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: _kBrownSoft)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: _kBrownSoft))),
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
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear offline cache', style: TextStyle(color: _kBrown)),
        content: Text(
            _pendingSync > 0
                ? 'You have $_pendingSync inspection(s) not yet synced. Clearing will DELETE them permanently. Continue?'
                : 'This clears cached assignments and inspection drafts stored on this device. Continue?',
            style: const TextStyle(color: _kBrownSoft)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: _kBrownSoft))),
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
      body: Container(
        color: const Color(0xFF241008),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(_kBgImage),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              // ===== Cream top bar =====
              Container(
                width: double.infinity,
                color: _kTopBar,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: _kOrange),
                          onPressed: () => Navigator.of(context).maybePop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.network(
                            'https://i.ibb.co/MDqJQhv9/27453318-8b7f-442d-88ca-5b69007d4e03.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.directions_boat, color: _kOrange, size: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text('Profile',
                            style: TextStyle(
                                fontFamily: 'Georgia',
                                fontFamilyFallback: ['Times New Roman', 'serif'],
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: _kBrown)),
                      ],
                    ),
                  ),
                ),
              ),
              // ===== Content over the photo =====
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: _kOrange))
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
                            _cardTitle(Icons.person_outline, 'Inspector Profile'),
                            const SizedBox(height: 16),
                            Row(children: [
                              Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(color: _kOrangeChip, shape: BoxShape.circle),
                                  child: const Icon(Icons.person, color: _kOrange, size: 30)),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_user?['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontFamily: 'Georgia',
                                        fontFamilyFallback: ['Times New Roman', 'serif'],
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: _kBrown)),
                                const SizedBox(height: 3),
                                Text(_user?['email'] ?? '', style: const TextStyle(fontSize: 14, color: _kBrownSoft)),
                                const SizedBox(height: 4),
                                Text((_user?['role'] ?? 'inspector').toString().replaceAll('_', ' '),
                                    style: const TextStyle(fontSize: 13, color: _kOrange, fontWeight: FontWeight.w700)),
                              ])),
                            ]),
                          ])),
                          const SizedBox(height: 16),
                          // Security
                          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _cardTitle(Icons.lock_outline, 'Security'),
                            const SizedBox(height: 6),
                            const Text('Change your account password. Requires internet connection.',
                                style: TextStyle(fontSize: 13.5, color: _kBrownSoft)),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: _changePassword,
                              icon: const Icon(Icons.lock_outline, size: 17, color: _kOrange),
                              label: const Text('Change password'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: _kOrange,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  side: const BorderSide(color: _kOrange, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                            ),
                          ])),
                          const SizedBox(height: 16),
                          // Device Info
                          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _cardTitle(Icons.smartphone_outlined, 'Device Info'),
                            const SizedBox(height: 14),
                            _kvRow('Platform', kIsWeb ? 'Web' : 'Mobile App'),
                            const SizedBox(height: 10),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Connection', style: TextStyle(fontSize: 14, color: _kBrownSoft)),
                              Row(children: [
                                Text(_online ? 'Online' : 'Offline',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _online ? _kGreen : _kBrownSoft)),
                                const SizedBox(width: 5),
                                Icon(Icons.circle, size: 9, color: _online ? _kGreen : _kBrownSoft),
                              ]),
                            ]),
                            const SizedBox(height: 10),
                            _kvRow('Pending sync', '$_pendingSync inspection(s)'),
                          ])),
                          const SizedBox(height: 16),
                          // Offline Storage
                          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _cardTitle(Icons.inventory_2_outlined, 'Offline Storage'),
                            const SizedBox(height: 6),
                            const Text('Cached assignments + inspection drafts stored on this device.',
                                style: TextStyle(fontSize: 13.5, color: _kBrownSoft)),
                            const SizedBox(height: 14),
                            SizedBox(width: double.infinity, child: ElevatedButton.icon(
                              onPressed: _clearCache,
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                              label: const Text('Clear offline data'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _kOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  elevation: 0),
                            )),
                          ])),
                          const SizedBox(height: 16),
                          // Sign Out
                          SizedBox(width: double.infinity, child: ElevatedButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text('Sign Out',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB03A2E),
                                minimumSize: const Size(0, 52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0),
                          )),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardTitle(IconData icon, String title) => Row(children: [
    Icon(icon, color: _kOrange, size: 20),
    const SizedBox(width: 9),
    Text(title,
        style: const TextStyle(
            fontFamily: 'Georgia',
            fontFamilyFallback: ['Times New Roman', 'serif'],
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _kBrown)),
  ]);

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ]),
    child: child,
  );

  Widget _kvRow(String k, String v) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(k, style: const TextStyle(fontSize: 14, color: _kBrownSoft)),
    Text(v, style: const TextStyle(fontSize: 14, color: _kBrown, fontWeight: FontWeight.w700)),
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
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Change password', style: TextStyle(color: _kBrown, fontWeight: FontWeight.w800)),
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
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _kBrownSoft))),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: _kOrange, foregroundColor: Colors.white),
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Update'),
        ),
      ],
    );
  }
}