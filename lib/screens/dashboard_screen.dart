import 'package:flutter/material.dart';
import '../api_service.dart';

// ===== RightKnots maritime palette =====
const _kPageBg = Color(0xFFF2EBDD);     // warm cream page background
const _kCard = Color(0xFFFAF4E8);       // card cream
const _kCardBorder = Color(0xFFE8D9C0);
const _kBrown = Color(0xFF3D2817);      // dark text
const _kBrownSoft = Color(0xFF8A6A4E);  // soft text
const _kOrange = Color(0xFFC2551B);     // accent
const _kOrangeChip = Color(0xFFF7E3D2); // icon circle background
const _kHeaderText = Color(0xFFF5EBDD); // cream text on dark header

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onGoToAssignments;
  const DashboardScreen({super.key, this.onGoToAssignments});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _user;
  List<dynamic> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final user = await ApiService.getUser();
    final all = await ApiService.getMyAssignments();
    if (!mounted) return;
    setState(() {
      _user = user;
      _assignments = all;
      _loading = false;
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  int _countByStatus(String status) => _assignments
      .where((a) => (a['status'] ?? '').toString().toLowerCase() == status.toLowerCase())
      .length;

  int get _assignedTodayCount {
    return _assignments.where((a) {
      if (a['due_date'] == null) return false;
      final due = DateTime.tryParse(a['due_date']);
      if (due == null) return false;
      return _isToday(due);
    }).length;
  }

  List<dynamic> get _todayAssignments {
    return _assignments.where((a) {
      final status = (a['status'] ?? '').toString().toLowerCase();
      return status == 'upcoming' || status == 'in_progress';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (_user?['name'] ?? 'Inspector').toString().split(' ').first;

    return Scaffold(
      backgroundColor: _kPageBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kOrange))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: _kOrange,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // ===== Ship banner with stats overlapping it =====
            Stack(
              children: [
                Column(
                  children: [
                    _headerBanner(firstName),
                    // cream strip behind lower half of stat cards
                    Container(height: 110, color: _kPageBg),
                  ],
                ),
                // stats grid pulled up to overlap the banner
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  child: _statsGrid(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _todaySection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Dark ship banner with greeting =====
  Widget _headerBanner(String name) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF241008),
        image: DecorationImage(
          image: NetworkImage('https://i.ibb.co/zh2hKsVV/dash.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo in cream frame
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF3E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.network(
                  'https://i.ibb.co/MDqJQhv9/27453318-8b7f-442d-88ca-5b69007d4e03.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.anchor, color: _kOrange, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_greeting()}, $name',
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: ['Times New Roman', 'serif'],
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _kHeaderText,
                        )),
                    const SizedBox(height: 3),
                    const Text("Here's your day at a glance",
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: ['Times New Roman', 'serif'],
                          fontSize: 14,
                          color: Color(0xFFD9B98F),
                        )),
                  ],
                ),
              ),
              // Online pill (cream with orange dot)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF3E7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: _kOrange, size: 9),
                    SizedBox(width: 6),
                    Text('Online',
                        style: TextStyle(
                            color: _kBrown,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsGrid() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.assignment_outlined, _assignedTodayCount.toString(), 'Assigned Today')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.play_arrow_rounded, _countByStatus('in_progress').toString(), 'In Progress')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.sync, _countByStatus('upcoming').toString(), 'Pending Sync')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.description_outlined, _countByStatus('submitted').toString(), 'Reports Ready')),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A3A12).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round orange icon chip
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: _kOrangeChip,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _kOrange, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['Times New Roman', 'serif'],
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: _kBrown,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: _kBrownSoft, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _todaySection() {
    final today = _todayAssignments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text("Today's Assignments",
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontFamilyFallback: ['Times New Roman', 'serif'],
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _kBrown,
                  )),
            ),
            TextButton(
              onPressed: widget.onGoToAssignments,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View all',
                      style: TextStyle(
                          color: _kOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward, size: 15, color: _kOrange),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (today.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: const Text('No assignments for today.',
                style: TextStyle(fontSize: 14, color: _kBrownSoft)),
          )
        else
          ...today.map((a) => _miniCard(a)),
      ],
    );
  }

  Widget _miniCard(dynamic a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Row(
        children: [
          // Round ship icon chip
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: _kOrangeChip,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_boat_filled,
                color: _kOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a['vessel'] ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kBrown)),
                const SizedBox(height: 2),
                Text(a['template'] ?? '—',
                    style: const TextStyle(fontSize: 13, color: _kBrownSoft)),
              ],
            ),
          ),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _kOrangeChip,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8C4A6)),
            ),
            child: Text(
              (a['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  color: _kOrange,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}