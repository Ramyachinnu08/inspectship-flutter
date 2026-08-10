import 'package:flutter/material.dart';
import '../api_service.dart';
import 'report_launcher.dart';

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
    // Show only submitted (completed with report)
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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111111),
        elevation: 0,
        surfaceTintColor: Colors.white,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.anchor, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('My Reports',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111111))),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filter,
            onSelected: (f) => setState(() => _filter = f),
            offset: const Offset(0, 40),
            itemBuilder: (_) => ['All', 'draft', 'final']
                .map((f) => PopupMenuItem<String>(value: f, child: Text(f)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF374151)),
                  const SizedBox(width: 6),
                  Text(_filter, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF6B7280)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFFF6B00),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildHowToUse(),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text(
                      'No reports yet. Complete an inspection to generate one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                ),
              )
            else
              ...filtered.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildReportCard(r),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToUse() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _howToOpen = !_howToOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 18, color: Color(0xFF1A2A5E)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('How to use',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                  ),
                  Icon(_howToOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF6B7280), size: 22),
                ],
              ),
            ),
          ),
          if (_howToOpen)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'View and download reports from your completed inspections. Tap a report card to open it.',
                      style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF6B7280))),
                  SizedBox(height: 10),
                  Text('• ready — viewable and downloadable as PDF.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.55)),
                  SizedBox(height: 4),
                  Text('• generating — still processing, check back soon.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.55)),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => ReportLauncher.open(context, Map<String, dynamic>.from(a)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 18, color: Color(0xFF1A2A5E)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(a['vessel'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '📅 ${date.day}/${date.month}/${date.year}    ${a['template'] ?? '—'}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A5E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('ready',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}