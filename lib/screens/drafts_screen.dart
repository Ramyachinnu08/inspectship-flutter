import 'package:flutter/material.dart';
import '../data/mock_store.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'inspection_screen.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});
  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  bool _helpOpen = true;

  @override
  Widget build(BuildContext context) {
    final drafts = MockStore.instance.drafts;
    return Scaffold(
      backgroundColor: AppColors.foam,
      body: SafeArea(
        child: ConstrainedContent(
          child: ListView(
            padding: EdgeInsets.symmetric(
                horizontal: Responsive.pagePad(context)),
            children: [
              const SizedBox(height: 14),
              _PageHeader(hasDrafts: drafts.isNotEmpty),
              const SizedBox(height: 18),
              _HowToUseCard(
                open: _helpOpen,
                onToggle: () => setState(() => _helpOpen = !_helpOpen),
              ),
              const SizedBox(height: 20),
              if (drafts.isEmpty)
                _EmptyState()
              else
                ...drafts.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DraftCard(
                    assignment: a,
                    onDelete: () => setState(() {
                      MockStore.instance.assignments.remove(a);
                    }),
                  ),
                )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final bool hasDrafts;
  const _PageHeader({required this.hasDrafts});

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
        const Expanded(
          child: Text('Offline Drafts',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
        ),
        ElevatedButton.icon(
          onPressed: hasDrafts
              ? () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Syncing… (mock)')))
              : null,
          icon: const Icon(Icons.sync, size: 18),
          label: const Text('Sync Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.inkSoft.withValues(alpha: .5),
            disabledForegroundColor: Colors.white,
            minimumSize: const Size(120, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
                  const Icon(Icons.menu_book_outlined,
                      size: 20, color: AppColors.ink),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('How to use',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.inkSoft),
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
                  _para(
                      'Shows sessions that were started but not yet synced to the server — either because you\'re offline or because uploads are still pending.'),
                  const SizedBox(height: 18),
                  _sectionTitle('Typical workflow'),
                  const SizedBox(height: 6),
                  _numItem(1,
                      'Check which sessions have pending answers, uploads, or submissions.'),
                  _numItem(2, 'Tap Resume to continue working on a session.',
                      boldWords: ['Resume']),
                  _numItem(3, 'Tap Retry All when you\'re back online to sync everything.',
                      boldWords: ['Retry All']),
                  const SizedBox(height: 18),
                  _sectionTitle('Key things on this page'),
                  const SizedBox(height: 6),
                  _bulletBold('Pending answers',
                      ' — answers saved locally but not yet sent.'),
                  _bulletBold('Pending uploads',
                      ' — photos/videos waiting for connectivity.'),
                  _bulletBold('Submit pending',
                      ' — the session was submitted offline and is queued.'),
                  _bulletBold('Error badge',
                      ' — shows the last sync error (e.g., upload timeout).'),
                  const SizedBox(height: 18),
                  _sectionTitle('Examples'),
                  const SizedBox(height: 6),
                  _bullet('"3 photos stuck uploading → reconnect Wi-Fi and tap Retry All"'),
                  _bullet('"Session fully answered but submitted offline → queued for sync"'),
                  const SizedBox(height: 18),
                  _sectionTitle('Best practice'),
                  const SizedBox(height: 6),
                  _bullet('Check this page when you\'re back on reliable connectivity.'),
                  _bullet(
                      'Don\'t start a new inspection if old drafts are still pending — sync first.'),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Icon(Icons.help_outline,
                          size: 16, color: AppColors.inkSoft),
                      SizedBox(width: 6),
                      Text('Need help? Open in full view',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.inkSoft,
                              fontWeight: FontWeight.w600)),
                    ],
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800));
  Widget _para(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13, height: 1.5, color: AppColors.inkSoft));
  Widget _numItem(int n, String t, {List<String> boldWords = const []}) {
    final spans = <InlineSpan>[TextSpan(text: '$n. ')];
    var remaining = t;
    for (final w in boldWords) {
      final i = remaining.indexOf(w);
      if (i < 0) continue;
      spans.add(TextSpan(text: remaining.substring(0, i)));
      spans.add(TextSpan(
          text: w,
          style: const TextStyle(fontWeight: FontWeight.w800)));
      remaining = remaining.substring(i + w.length);
    }
    spans.add(TextSpan(text: remaining));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
          text: TextSpan(
              style: const TextStyle(
                  fontSize: 13, height: 1.55, color: AppColors.inkSoft),
              children: spans)),
    );
  }

  Widget _bullet(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 10),
          child: Icon(Icons.circle, size: 5, color: AppColors.inkSoft),
        ),
        Expanded(
          child: Text(t,
              style: const TextStyle(
                  fontSize: 13, height: 1.55, color: AppColors.inkSoft)),
        )
      ],
    ),
  );

  Widget _bulletBold(String bold, String rest) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 10),
          child: Icon(Icons.circle, size: 5, color: AppColors.inkSoft),
        ),
        Expanded(
          child: RichText(
              text: TextSpan(
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: AppColors.inkSoft),
                  children: [
                    TextSpan(
                        text: bold,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    TextSpan(text: rest),
                  ])),
        )
      ],
    ),
  );
}

class _DraftCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onDelete;
  const _DraftCard({required this.assignment, required this.onDelete});

  String _isoTimestamp() {
    final d = DateTime.now().subtract(const Duration(hours: 6));
    return d.toIso8601String();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete draft?'),
        content: Text(
            'This will permanently remove the draft for ${assignment.vesselName}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.fail),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) onDelete();
  }

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
                child: Text(a.vesselName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => InspectionScreen(assignment: a))),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.line),
                  minimumSize: const Size(90, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                child: const Text('Resume'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.fail),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 14, color: AppColors.inkSoft),
              const SizedBox(width: 4),
              Flexible(
                child: Text('Last saved: ${_isoTimestamp()}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkSoft),
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
            decoration: BoxDecoration(
              color: AppColors.pass.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: AppColors.pass, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('All synced',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('No offline drafts pending',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
        ],
      ),
    );
  }
}