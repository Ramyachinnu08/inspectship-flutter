import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../api_service.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});
  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  bool _helpOpen = false;
  List<dynamic> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final all = await ApiService.getMyAssignments();
    final drafts = all.where((a) {
      final status = (a['status'] ?? '').toString().toLowerCase();
      return status == 'in_progress' && a['has_session'] == true;
    }).toList();
    if (!mounted) return;
    setState(() {
      _drafts = drafts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.foam,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.signal))
            : RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.signal,
          child: ConstrainedContent(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: Responsive.pagePad(context)),
              children: [
                const SizedBox(height: 14),
                _PageHeader(hasDrafts: _drafts.isNotEmpty, onSync: _loadData),
                const SizedBox(height: 18),
                _HowToUseCard(open: _helpOpen, onToggle: () => setState(() => _helpOpen = !_helpOpen)),
                const SizedBox(height: 20),
                if (_drafts.isEmpty)
                  const _EmptyState()
                else
                  ..._drafts.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DraftCard(assignment: a),
                  )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final bool hasDrafts;
  final VoidCallback onSync;
  const _PageHeader({required this.hasDrafts, required this.onSync});

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
          decoration: BoxDecoration(color: AppColors.signal, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.anchor, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Offline Drafts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ),
        ElevatedButton.icon(
          onPressed: hasDrafts ? onSync : null,
          icon: const Icon(Icons.sync, size: 18),
          label: const Text('Sync Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.inkSoft.withValues(alpha: .5),
            disabledForegroundColor: Colors.white,
            minimumSize: const Size(120, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 20, color: AppColors.ink),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('How to use', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                  Icon(open ? Icons.expand_less : Icons.expand_more, color: AppColors.inkSoft),
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
                  const Divider(color: AppColors.line, height: 1),
                  const SizedBox(height: 16),
                  _sectionTitle('What this page is for'),
                  const SizedBox(height: 6),
                  _para('Shows sessions that were started but not yet completed. Resume them or sync when back online.'),
                  const SizedBox(height: 18),
                  _sectionTitle('Typical workflow'),
                  const SizedBox(height: 6),
                  _numItem(1, 'Check which sessions have pending work.'),
                  _numItem(2, 'Tap Resume to continue working on a session.', boldWords: ['Resume']),
                  _numItem(3, 'Tap Sync Now when back online to sync everything.', boldWords: ['Sync Now']),
                  const SizedBox(height: 18),
                  _sectionTitle('Best practice'),
                  const SizedBox(height: 6),
                  _bullet('Check this page when back on reliable connectivity.'),
                  _bullet('Don\'t start a new inspection if old drafts are pending — sync first.'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800));
  Widget _para(String t) => Text(t, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.inkSoft));
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
      child: RichText(text: TextSpan(style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.inkSoft), children: spans)),
    );
  }

  Widget _bullet(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 6, right: 10), child: Icon(Icons.circle, size: 5, color: AppColors.inkSoft)),
        Expanded(child: Text(t, style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.inkSoft))),
      ],
    ),
  );
}

class _DraftCard extends StatelessWidget {
  final dynamic assignment;
  const _DraftCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
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
              Expanded(
                child: Text(a['vessel'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
              ),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Resume ${a['vessel']} — coming soon')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.line),
                  minimumSize: const Size(90, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                child: const Text('Resume'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 14, color: AppColors.inkSoft),
              const SizedBox(width: 4),
              Flexible(
                child: Text(a['template'] ?? '—',
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
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
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.pass.withValues(alpha: .12), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: AppColors.pass, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('All synced', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('No offline drafts pending', style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
        ],
      ),
    );
  }
}