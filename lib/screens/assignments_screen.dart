import 'package:flutter/material.dart';
import '../api_service.dart';
import 'ai_assistant_screen.dart';
import '../offline_store.dart';
import 'inspection_launcher.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<dynamic> _assignments = [];
  bool _loading = true;
  bool _howToOpen = false;
  String _filter = 'All';
  String _inspectorName = '';
  bool _online = true;
  int _pendingSync = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    OfflineStore.instance.onlineStream().listen((online) {
      if (mounted) setState(() => _online = online);
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final user = await ApiService.getUser();
    _inspectorName = (user?['name'] ?? 'Ramya').toString().split(' ').first;
    _online = await OfflineStore.instance.isOnline();
    final data = await OfflineStore.instance.getAssignments();
    if (!mounted) return;
    setState(() {
      _assignments = data;
      _pendingSync = OfflineStore.instance.pendingSyncCount;
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

  List<dynamic> get _filteredAssignments {
    if (_filter == 'All') return _assignments;
    return _assignments.where((a) {
      final status = (a['status'] ?? '').toString().toLowerCase();
      if (_filter == 'Upcoming') return status == 'upcoming';
      if (_filter == 'In Progress') return status == 'in_progress';
      if (_filter == 'Overdue') return status == 'overdue';
      if (_filter == 'Completed') return status == 'submitted';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
        backgroundColor: const Color(0xFFF06B26),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
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
              _header(_inspectorName),
              const SizedBox(height: 16),
              _howToUse(),
              const SizedBox(height: 16),
              _filterRow(),
              const SizedBox(height: 12),
              if (_filteredAssignments.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 60, color: Color(0xFF9CA3AF)),
                      const SizedBox(height: 12),
                      Text(
                        _assignments.isEmpty ? 'No assignments yet' : 'No $_filter assignments',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                )
              else
                ..._filteredAssignments.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _card(a),
                )),
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
              const Text('My Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('$name Poojary', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _online ? const Color(0xFF1A2A5E) : const Color(0xFF9CA3AF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_online ? Icons.wifi : Icons.wifi_off, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(_online ? 'Online' : 'Offline', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _howToUse() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _howToOpen = !_howToOpen),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 20, color: Color(0xFF6B7280)),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('How to use', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                  Icon(_howToOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF6B7280)),
                ],
              ),
            ),
          ),
          if (_howToOpen)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                '• Tap an assignment card to start or resume inspection.\n'
                    '• Use the filter to view specific statuses.\n'
                    '• Pull down to refresh the list.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return Row(
      children: [
        const Text('Filter:', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButton<String>(
            value: _filter,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Upcoming', child: Text('Upcoming')),
              DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
              DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
            ],
            onChanged: (v) => setState(() => _filter = v ?? 'All'),
          ),
        ),
      ],
    );
  }

  Widget _card(dynamic a) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    DateTime? due;
    if (a['due_date'] != null) due = DateTime.tryParse(a['due_date']);
    final dateStr = due != null ? '${due.day} ${m[due.month - 1]} ${due.year}' : 'No due date';
    final status = (a['status'] ?? 'upcoming').toString();

    String statusLabel;
    Color statusBg;
    Color statusFg;
    if (status == 'upcoming') {
      statusLabel = 'Upcoming';
      statusBg = const Color(0xFFE0E7FF);
      statusFg = const Color(0xFF3730A3);
    } else if (status == 'in_progress') {
      statusLabel = 'In Progress';
      statusBg = const Color(0xFFE0E7FF);
      statusFg = const Color(0xFF3730A3);
    } else if (status == 'overdue') {
      statusLabel = 'Overdue';
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFF991B1B);
    } else if (status == 'submitted') {
      statusLabel = 'Completed';
      statusBg = const Color(0xFFE0E7FF);
      statusFg = const Color(0xFF3730A3);
    } else {
      statusLabel = 'Report Ready';
      statusBg = const Color(0xFFE0E7FF);
      statusFg = const Color(0xFF3730A3);
    }

    final bool isSubmitted = status == 'submitted';
    final btnLabel = status == 'upcoming' ? 'Start' : (isSubmitted ? 'Submitted' : 'Resume');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_boat_filled, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(a['vessel'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    Text((a['vessel_imo'] ?? '').toString().replaceAll('IMO ', ''),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(dateStr, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    const SizedBox(width: 16),
                    const Icon(Icons.description_outlined, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(a['template'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusFg)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Text('standard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: isSubmitted
                  ? null
                  : () async {
                await InspectionLauncher.open(context, Map<String, dynamic>.from(a));
                _loadData();
              },
              icon: Icon(isSubmitted ? Icons.check_circle : Icons.arrow_forward, size: 18),
              label: Text(btnLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSubmitted ? const Color(0xFF22C55E) : const Color(0xFF1A2A5E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF22C55E),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}