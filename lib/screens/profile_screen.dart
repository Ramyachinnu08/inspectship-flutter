import 'package:flutter/material.dart';
import '../data/mock_store.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _appVersion = '1.0.0';
  static const _userAgent = 'Mozilla/5.0';

  Future<void> _confirm(BuildContext context, String title, String body,
      String action, VoidCallback onOk) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.fail),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action)),
        ],
      ),
    );
    if (ok == true) onOk();
  }

  @override
  Widget build(BuildContext context) {
    final store = MockStore.instance;
    return Scaffold(
      backgroundColor: AppColors.foam,
      body: SafeArea(
        child: ConstrainedContent(
          child: ListView(
            padding: EdgeInsets.symmetric(
                horizontal: Responsive.pagePad(context)),
            children: [
              const SizedBox(height: 14),
              _PageHeader(),
              const SizedBox(height: 20),

              _SectionCard(
                icon: Icons.person_outline,
                title: 'Inspector Profile',
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.person,
                          size: 32, color: AppColors.navy),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${store.inspectorName} Poojary',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          const Text('ramyapoojary871@gmail.com',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inkSoft)),
                          const SizedBox(height: 2),
                          const Text('Inspector',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.vpn_key_outlined,
                title: 'Security',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Change your account password. Requires internet connection.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.inkSoft,
                            height: 1.4)),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Opens change-password flow (mock)'))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.line),
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Change password'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.smartphone_outlined,
                title: 'Device Info',
                child: Column(
                  children: [
                    _kv('User Agent', _userAgent),
                    const SizedBox(height: 8),
                    _kv('Online', 'Yes'),
                    const SizedBox(height: 8),
                    _kv('App Version', _appVersion),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.storage_outlined,
                title: 'Offline Storage',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cached data for offline use.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.inkSoft,
                            height: 1.4)),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => _confirm(
                        context,
                        'Clear local cache?',
                        'This removes downloaded assignments and cached templates from this device. Unsynced drafts will not be deleted.',
                        'Clear',
                            () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Local cache cleared'))),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fail,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear Local Cache'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.delete_outline,
                title: 'Dev: Wipe Data',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Remove all test data and reset IDs. Auth (users, sessions) is preserved. Only available on dev.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.inkSoft,
                            height: 1.4)),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => _confirm(
                        context,
                        'Wipe dev data?',
                        'This removes all test data and resets IDs. Auth is preserved.',
                        'Wipe',
                            () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dev data wiped'))),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fail,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Wipe Dev Data'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _confirm(
                  context,
                  'Sign out?',
                  'You\'ll need internet to sign back in.',
                  'Sign out',
                      () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fail,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.inkSoft)),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.ink,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.signal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.anchor, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Text('Profile',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}