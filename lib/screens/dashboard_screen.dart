import 'package:flutter/material.dart';
import '../api_service.dart';

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
    // Show upcoming + in_progress assignments
    return _assignments.where((a) {
      final status = (a['status'] ?? '').toString().toLowerCase();
      return status == 'upcoming' || status == 'in_progress';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (_user?['name'] ?? 'Inspector').toString().split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A2A5E)))
            : RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF1A2A5E),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _header(firstName),
              const SizedBox(height: 20),
              _statsGrid(),
              const SizedBox(height: 24),
              _todaySection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String name) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.anchor, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_greeting()}, $name',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Text("Here's your day at a glance",
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A5E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Text('Online',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statsGrid() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.assignment_outlined, _assignedTodayCount.toString(), 'Assigned Today', const Color(0xFF6B7280))),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.play_arrow, _countByStatus('in_progress').toString(), 'In Progress', const Color(0xFFFF6B00))),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.sync, _countByStatus('upcoming').toString(), 'Pending Sync', const Color(0xFF6B7280))),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.description_outlined, _countByStatus('submitted').toString(), 'Reports Ready', const Color(0xFF22C55E))),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
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
            const Expanded(child: Text("Today's Assignments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            TextButton(
              onPressed: widget.onGoToAssignments,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View all', style: TextStyle(color: Color(0xFF1A2A5E), fontWeight: FontWeight.w700, fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: Color(0xFF1A2A5E)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (today.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: const Text('No assignments for today.', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          )
        else
          ...today.map((a) => _miniCard(a)),
      ],
    );
  }

  Widget _miniCard(dynamic a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_boat_filled, color: Color(0xFFFF6B00), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a['vessel'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(a['template'] ?? '—',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Text(
            (a['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Color(0xFF1A2A5E), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}