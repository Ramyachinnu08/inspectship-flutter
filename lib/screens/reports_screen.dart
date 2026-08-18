import 'package:flutter/material.dart';
import '../api_service.dart';
import 'report_launcher.dart';

// ===== RightKnot maritime palette =====
const _kTopBar = Color(0xFFFAF3E7);
const _kCard = Color(0xFFFDF8ED);
const _kBrown = Color(0xFF3D2817);
const _kBrownSoft = Color(0xFF8A6A4E);
const _kOrange = Color(0xFFE8630A);
const _kOrangeChip = Color(0xFFF7E3D2);
const _kDarkPill = Color(0xFF3A2A1A); // dark "ready" pill

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _filter = 'All';
  bool _howToOpen = false;
  List<dynamic> _reports = [];
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
      _reports = submitted;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All' ? _reports : _reports;

    return Scaffold(
      body: Container(
        color: const Color(0xFF241008),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://i.ibb.co/wZczjrvC/report.png'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.network(
                            'https://i.ibb.co/8g7pqvvr/knot.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.directions_boat, color: _kOrange, size: 26),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text('My Reports',
                              style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontFamilyFallback: ['Times New Roman', 'serif'],
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: _kBrown)),
                        ),
                        // Filter dropdown: "All" with funnel icon
                        PopupMenuButton<String>(
                          initialValue: _filter,
                          onSelected: (f) => setState(() => _filter = f),
                          offset: const Offset(0, 40),
                          color: _kCard,
                          itemBuilder: (_) => ['All', 'draft', 'final']
                              .map((f) => PopupMenuItem<String>(
                              value: f,
                              child: Text(f, style: const TextStyle(color: _kBrown))))
                              .toList(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.filter_alt_outlined, size: 18, color: _kBrown),
                                const SizedBox(width: 6),
                                Text(_filter,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _kBrown)),
                                const Icon(Icons.keyboard_arrow_down, size: 20, color: _kOrange),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHowToUse(),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: _kCard,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text(
                                'No reports yet. Complete an inspection to generate one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _kBrownSoft, fontSize: 14)),
                          ),
                        )
                      else
                        ...filtered.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildReportCard(r),
                        )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowToUse() {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _howToOpen = !_howToOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  Icon(_howToOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: _kBrownSoft, size: 22),
                ],
              ),
            ),
          ),
          if (_howToOpen)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE8D9C0), width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'View and download reports from your completed inspections. Tap a report card to open it.',
                      style: TextStyle(fontSize: 13, height: 1.6, color: _kBrownSoft)),
                  SizedBox(height: 10),
                  Text('• ready — viewable and downloadable as PDF.',
                      style: TextStyle(fontSize: 13, color: _kBrownSoft, height: 1.55)),
                  SizedBox(height: 4),
                  Text('• generating — still processing, check back soon.',
                      style: TextStyle(fontSize: 13, color: _kBrownSoft, height: 1.55)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportCard(dynamic a) {
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
        onTap: () => ReportLauncher.open(context, Map<String, dynamic>.from(a)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              // Rounded document icon chip
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _kOrangeChip,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.description_outlined,
                    color: _kOrange, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a['vessel'] ?? 'Unknown',
                        style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: ['Times New Roman', 'serif'],
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _kBrown),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 15, color: _kOrange),
                        const SizedBox(width: 5),
                        Text('${date.day}/${date.month}/${date.year}',
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
              const SizedBox(width: 16),
              // Dark rounded "ready" pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: _kDarkPill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('ready',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF5EBDD))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}