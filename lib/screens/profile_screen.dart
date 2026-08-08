import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../api_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser();
    setState(() {
      _user = user;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.of(context).maybePop()),
        title: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.directions_boat, color: Colors.white, size: 20)),
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
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password change coming soon'))),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), side: const BorderSide(color: Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Change password', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ])),
                const SizedBox(height: 16),
                // Device Info
                _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: const [Icon(Icons.smartphone_outlined, color: Colors.black, size: 20), SizedBox(width: 8), Text('Device Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black))]),
                  const SizedBox(height: 14),
                  _kvRow('User Agent', kIsWeb ? 'Mozilla/5.0' : 'Flutter App'),
                  const SizedBox(height: 10),
                  _kvRow('Online', 'Yes'),
                ])),
                const SizedBox(height: 16),
                // Offline Storage
                _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: const [Icon(Icons.storage_outlined, color: Colors.black, size: 20), SizedBox(width: 8), Text('Offline Storage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black))]),
                  const SizedBox(height: 6),
                  const Text('Cached data for offline use.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    onPressed: () async {
                      await ApiService.clearToken();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline cache cleared')));
                    },
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