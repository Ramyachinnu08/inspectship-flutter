import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../api_service.dart';

// ===== RightKnots maritime palette =====
const _kTopBar = Color(0xFFFAF3E7);
const _kCard = Color(0xFFFDF8ED);
const _kBrown = Color(0xFF3D2817);
const _kBrownSoft = Color(0xFF8A6A4E);
const _kOrange = Color(0xFFE8630A);
const _kOrangeChip = Color(0xFFF7E3D2);
const _kDarkBtn = Color(0xFF241008);
const _kGreen = Color(0xFF4C7A3C);
const _kGreenChip = Color(0xFFE4EFDD);

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
      body: Container(
        color: const Color(0xFF241008),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://i.ibb.co/DHvybpHy/his.jpg'),
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
                    child: const _PageHeader(),
                  ),
                ),
              ),
              // ===== Content over the photo =====
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: _kOrange))
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
                        if (_submitted.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.center,
                            child: const Text('No completed inspections yet.',
                                style: TextStyle(color: _kBrownSoft, fontSize: 14)),
                          )
                        else
                          ..._submitted.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _HistoryCard(assignment: a),
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
  const _PageHeader();
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
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kOrange, width: 2),
          ),
          child: Image.network(
            'https://i.ibb.co/MDqJQhv9/27453318-8b7f-442d-88ca-5b69007d4e03.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.anchor, color: _kOrange, size: 24),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text('History',
              style: TextStyle(
                  fontFamily: 'Georgia',
                  fontFamilyFallback: ['Times New Roman', 'serif'],
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: _kBrown)),
        ),
        // Dark brown "Sync Now" with orange icon + text (matches mockup)
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('History is up to date')),
            );
          },
          icon: const Icon(Icons.history, size: 18, color: _kOrange),
          label: const Text('Sync Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kDarkBtn,
            foregroundColor: _kOrange,
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
                            color: _kBrown)),
                  ),
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

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kBrown));
  Widget _para(String t) => Text(t, style: const TextStyle(fontSize: 13, height: 1.5, color: _kBrownSoft));
  Widget _numItem(int n, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text('$n. $t', style: const TextStyle(fontSize: 13, height: 1.55, color: _kBrownSoft)),
  );
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
  Widget _bulletBold(String bold, String rest) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 6, right: 10), child: Icon(Icons.circle, size: 5, color: _kBrownSoft)),
        Expanded(
          child: RichText(
              text: TextSpan(
                  style: const TextStyle(fontSize: 13, height: 1.55, color: _kBrownSoft),
                  children: [
                    TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w800, color: _kBrown)),
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
      color: _kCard,
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View report for ${a['vessel']} — coming soon')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Rounded ship icon chip
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _kOrangeChip,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_boat_filled,
                    color: Color(0xFF7A2E08), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(a['vessel'] ?? 'Unknown',
                              style: const TextStyle(
                                  fontFamily: 'Georgia',
                                  fontFamilyFallback: ['Times New Roman', 'serif'],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _kBrown),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 10),
                        Text((a['vessel_imo'] ?? '').toString().replaceAll('IMO ', ''),
                            style: const TextStyle(fontSize: 13, color: _kBrownSoft)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 15, color: _kOrange),
                        const SizedBox(width: 5),
                        Text(_formatDate(date),
                            style: const TextStyle(fontSize: 13, color: _kBrownSoft)),
                        const SizedBox(width: 10),
                        const Text('|', style: TextStyle(color: Color(0xFFDECBAB))),
                        const SizedBox(width: 10),
                        const Icon(Icons.description_outlined, size: 15, color: _kOrange),
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
              ),
              const SizedBox(width: 12),
              // Green "Ready" pill with check
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _kGreenChip,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: _kGreen),
                    SizedBox(width: 5),
                    Text('Ready',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _kGreen)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}