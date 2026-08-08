import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _helpOpen = false;
  List<dynamic> _submitted = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final all = await ApiService.getMyAssignments();
    final submitted = all.where((a) => (a['status'] ?? '').toString().toLowerCase() == 'submitted').toList();
    if (!mounted) return;
    setState(() {
      _submitted = submitted;
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
                const _PageHeader(),
                const SizedBox(height: 18),
                _HowToUseCard(open: _helpOpen, onToggle: () => setState(() => _helpOpen = !_helpOpen)),
                const SizedBox(height: 20),
                if (_submitted.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    alignment: Alignment.center,
                    child: const Text('No completed inspections yet.',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
                  )
                else
                  ..._submitted.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HistoryCard(assignment: a),
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
  const _PageHeader();
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
        const Text('History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
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
                  const Expanded(
                    child: Text('How to use', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
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
                  _para('View all past sessions you\'ve completed. Filter by vessel, date, or status. Tap a session to view its report.'),
                  const SizedBox(height: 18),
                  _sectionTitle('Typical workflow'),
                  const SizedBox(height: 6),
                  _numItem(1, 'Browse your completed inspections.'),
                  _numItem(2, 'Tap a card to view the report or findings.'),
                  const SizedBox(height: 18),
                  _sectionTitle('Key things on this page'),
                  const SizedBox(height: 6),
                  _bulletBold('Report status', ' — Ready (downloadable), Generating, or Needs Review.'),
                  _bulletBold('Findings count', ' — number of findings from that inspection.'),
                  const SizedBox(height: 18),
                  _sectionTitle('Best practice'),
                  const SizedBox(height: 6),
                  _bullet('Review previous findings before starting a new inspection on the same vessel.'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800));
  Widget _para(String t) => Text(t, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.inkSoft));
  Widget _numItem(int n, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text('$n. $t', style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.inkSoft)),
  );
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
  Widget _bulletBold(String bold, String rest) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 6, right: 10), child: Icon(Icons.circle, size: 5, color: AppColors.inkSoft)),
        Expanded(
          child: RichText(
              text: TextSpan(
                  style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.inkSoft),
                  children: [
                    TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                    TextSpan(text: rest),
                  ])),
        ),
      ],
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  final dynamic assignment;
  const _HistoryCard({required this.assignment});

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    DateTime date = DateTime.now();
    if (a['due_date'] != null) {
      date = DateTime.tryParse(a['due_date']) ?? DateTime.now();
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View report for ${a['vessel']} — coming soon')),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_boat_filled, size: 20, color: AppColors.ink),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(a['vessel'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 10),
                        Text((a['vessel_imo'] ?? '').toString().replaceAll('IMO ', ''),
                            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 14, color: AppColors.inkSoft),
                        const SizedBox(width: 4),
                        Text(_formatDate(date),
                            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                        const SizedBox(width: 16),
                        const Icon(Icons.description_outlined, size: 14, color: AppColors.inkSoft),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(a['template'] ?? '—',
                              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.pass.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Ready',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.pass)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}