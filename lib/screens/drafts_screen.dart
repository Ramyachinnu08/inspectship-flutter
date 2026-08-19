import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../api_service.dart';
import '../offline_store.dart';
import 'inspection_launcher.dart';

// ===== RightKnots maritime palette =====
const _kTopBar = Color(0xFFFAF3E7);      // cream top strip
const _kCard = Color(0xFFFDF8ED);        // card cream
const _kBrown = Color(0xFF3D2817);
const _kBrownSoft = Color(0xFF8A6A4E);
const _kOrange = Color(0xFFE8630A);
const _kDarkBtn = Color(0xFF241008);     // dark brown Sync Now button

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});
  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  bool _helpOpen = false;
  List<dynamic> _drafts = [];
  bool _loading = true;
  bool _syncing = false;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    // Drafts = assignments that are in progress OR have local pending data
    final all = await OfflineStore.instance.getAssignments();
    final drafts = all.where((a) {
      final status = (a['status'] ?? '').toString().toLowerCase();
      final pending = a['_pending_sync'] == true;
      return status == 'in_progress' || pending;
    }).toList();
    if (!mounted) return;
    setState(() {
      _drafts = drafts;
      _pending = OfflineStore.instance.pendingSyncCount;
      _loading = false;
    });
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    if (!await OfflineStore.instance.isOnline()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection. Connect to sync.')),
        );
      }
      return;
    }
    setState(() => _syncing = true);
    final result = await OfflineStore.instance.syncNow();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message']?.toString() ?? 'Sync complete')),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Full-screen ship background
        color: const Color(0xFF241008),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://i.ibb.co/whMBS7Sw/dra.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              // ===== Cream top bar strip =====
              Container(
                width: double.infinity,
                color: _kTopBar,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: _PageHeader(
                      hasDrafts: _drafts.isNotEmpty || _pending > 0,
                      pending: _pending,
                      syncing: _syncing,
                      onSync: _syncNow,
                    ),
                  ),
                ),
              ),
              // ===== Content floating over the photo =====
              Expanded(
                child: _loading
                    ? const Center(
                    child: CircularProgressIndicator(color: _kOrange))
                    : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _kOrange,
                  child: ConstrainedContent(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                          horizontal: Responsive.pagePad(context)),
                      children: [
                        const SizedBox(height: 20),
                        _HowToUseCard(
                            open: _helpOpen,
                            onToggle: () =>
                                setState(() => _helpOpen = !_helpOpen)),
                        const SizedBox(height: 20),
                        if (_drafts.isEmpty)
                          const _EmptyState()
                        else
                          ..._drafts.map((a) => Padding(
                            padding:
                            const EdgeInsets.only(bottom: 14),
                            child: _DraftCard(
                                assignment: a, onChanged: _loadData),
                          )),
                        const SizedBox(height: 16),
                      ],
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
}

class _PageHeader extends StatelessWidget {
  final bool hasDrafts;
  final int pending;
  final bool syncing;
  final VoidCallback onSync;
  const _PageHeader({required this.hasDrafts, required this.pending, required this.syncing, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: _kOrange),
          onPressed: () => Navigator.of(context).maybePop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kOrange, width: 2),
          ),
          child: Image.network(
            'https://i.ibb.co/MDqJQhv9/27453318-8b7f-442d-88ca-5b69007d4e03.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.anchor, color: _kOrange, size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Offline Drafts',
                  style: TextStyle(
                      fontFamily: 'Georgia',
                      fontFamilyFallback: ['Times New Roman', 'serif'],
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: _kBrown)),
              if (pending > 0)
                Text('$pending pending sync',
                    style: const TextStyle(fontSize: 12, color: _kBrownSoft)),
            ],
          ),
        ),
        // Dark brown "Sync Now" with orange icon + text
        ElevatedButton.icon(
          onPressed: hasDrafts && !syncing ? onSync : null,
          icon: syncing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kOrange))
              : const Icon(Icons.sync, size: 18, color: _kOrange),
          label: Text(syncing ? 'Syncing…' : 'Sync Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kDarkBtn,
            foregroundColor: _kOrange,
            disabledBackgroundColor: _kDarkBtn.withOpacity(0.4),
            disabledForegroundColor: const Color(0xFFCB9A6C),
            elevation: 0,
            minimumSize: const Size(130, 46),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _HowToUseCard extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;
  const _HowToUseCard({required this.open, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 20, color: _kOrange),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('How to use',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _kBrown))),
                  Icon(open ? Icons.expand_less : Icons.expand_more, color: _kBrownSoft),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFE8D9C0), height: 1),
                  const SizedBox(height: 16),
                  _sectionTitle('What this page is for'),
                  const SizedBox(height: 6),
                  _para('Shows inspections started or completed offline. Resume them or tap Sync Now when back online to upload.'),
                  const SizedBox(height: 18),
                  _sectionTitle('Typical workflow'),
                  const SizedBox(height: 6),
                  _numItem(1, 'Do inspections offline at sea — they save on the device.'),
                  _numItem(2, 'Tap Resume to continue working on a session.', boldWords: ['Resume']),
                  _numItem(3, 'Tap Sync Now when back online to upload everything.', boldWords: ['Sync Now']),
                  const SizedBox(height: 18),
                  _sectionTitle('Best practice'),
                  const SizedBox(height: 6),
                  _bullet('Sync as soon as you regain a reliable connection.'),
                  _bullet('Check the pending count before leaving port.'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kBrown));
  Widget _para(String t) => Text(t, style: const TextStyle(fontSize: 13, height: 1.5, color: _kBrownSoft));
  Widget _numItem(int n, String t, {List<String> boldWords = const []}) {
    final spans = <InlineSpan>[TextSpan(text: '$n. ')];
    var remaining = t;
    for (final w in boldWords) {
      final i = remaining.indexOf(w);
      if (i < 0) continue;
      spans.add(TextSpan(text: remaining.substring(0, i)));
      spans.add(TextSpan(text: w, style: const TextStyle(fontWeight: FontWeight.w800)));
      remaining = remaining.substring(i + w.length);
    }
    spans.add(TextSpan(text: remaining));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(text: TextSpan(style: const TextStyle(fontSize: 13, height: 1.55, color: _kBrownSoft), children: spans)),
    );
  }

  Widget _bullet(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 6, right: 10), child: Icon(Icons.circle, size: 5, color: _kBrownSoft)),
        Expanded(child: Text(t, style: const TextStyle(fontSize: 13, height: 1.55, color: _kBrownSoft))),
      ],
    ),
  );
}

class _DraftCard extends StatelessWidget {
  final dynamic assignment;
  final VoidCallback onChanged;
  const _DraftCard({required this.assignment, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final pending = a['_pending_sync'] == true;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a['vessel'] ?? 'Unknown',
                    style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontFamilyFallback: ['Times New Roman', 'serif'],
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _kBrown),
                    overflow: TextOverflow.ellipsis),
              ),
              if (pending)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF7E3D2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8C4A6))),
                  child: const Text('Pending sync',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _kOrange)),
                ),
              OutlinedButton(
                onPressed: () async {
                  await InspectionLauncher.open(context, Map<String, dynamic>.from(a));
                  onChanged();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kOrange,
                  side: const BorderSide(color: _kOrange, width: 1.3),
                  minimumSize: const Size(100, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: const Text('Resume'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_border, size: 16, color: _kOrange),
              const SizedBox(width: 5),
              Flexible(
                child: Text(a['template'] ?? '—',
                    style: const TextStyle(fontSize: 13, color: _kBrownSoft),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Color(0xFFE8EDD6), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Color(0xFF7A8C3C), size: 40),
          ),
          const SizedBox(height: 16),
          const Text('All synced',
              style: TextStyle(
                  fontFamily: 'Georgia',
                  fontFamilyFallback: ['Times New Roman', 'serif'],
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _kBrown)),
          const SizedBox(height: 4),
          const Text('No offline drafts pending', style: TextStyle(color: _kBrownSoft, fontSize: 14)),
        ],
      ),
    );
  }
}