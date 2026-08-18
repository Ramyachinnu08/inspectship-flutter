import 'package:flutter/material.dart';
import '../api_service.dart';
import 'ai_assistant_screen.dart';
import '../offline_store.dart';
import 'inspection_launcher.dart';

// ===== RightKnot maritime palette =====
const _kPageBg = Color(0xFFF2EBDD);
const _kCard = Color(0xFFFAF4E8);
const _kCardBorder = Color(0xFFE8D9C0);
const _kBrown = Color(0xFF3D2817);
const _kBrownSoft = Color(0xFF8A6A4E);
const _kOrange = Color(0xFFC2551B);
const _kOrangeDeep = Color(0xFFA23E0E);
const _kOrangeChip = Color(0xFFF7E3D2);
const _kGreen = Color(0xFF7A8C3C);      // olive green (Submitted)
const _kGreenChip = Color(0xFFE8EDD6);
const _kHeaderText = Color(0xFFF5EBDD);

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

  // Order: incomplete work first (in_progress, overdue, upcoming), completed/submitted last
  int _statusRank(String status) {
    switch (status) {
      case 'in_progress': return 0;
      case 'overdue': return 1;
      case 'upcoming': return 2;
      case 'submitted':
      case 'approved':
      case 'completed': return 3;
      default: return 2;
    }
  }

  List<dynamic> get _filteredAssignments {
    List<dynamic> list;
    if (_filter == 'All') {
      list = List.from(_assignments);
    } else {
      list = _assignments.where((a) {
        final status = (a['status'] ?? '').toString().toLowerCase();
        if (_filter == 'Upcoming') return status == 'upcoming';
        if (_filter == 'In Progress') return status == 'in_progress';
        if (_filter == 'Overdue') return status == 'overdue';
        if (_filter == 'Completed') return status == 'submitted' || status == 'approved' || status == 'completed';
        return true;
      }).toList();
    }
    // sort: incomplete first, completed/submitted last
    list.sort((a, b) {
      final sa = _statusRank((a['status'] ?? '').toString().toLowerCase());
      final sb = _statusRank((b['status'] ?? '').toString().toLowerCase());
      return sa.compareTo(sb);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kOrange, _kOrangeDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: _kOrangeDeep.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          label: const Text('AI Assistant',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['Times New Roman', 'serif'],
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              )),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kOrange))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: _kOrange,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // ===== Ship banner with "How to use" bar overlapping =====
            Stack(
              children: [
                Column(
                  children: [
                    _headerBanner(),
                    Container(height: 30, color: _kPageBg),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  child: _howToUse(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _filterRow(),
                  const SizedBox(height: 14),
                  if (_filteredAssignments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          const Icon(Icons.inbox_outlined,
                              size: 60, color: _kBrownSoft),
                          const SizedBox(height: 12),
                          Text(
                            _assignments.isEmpty
                                ? 'No assignments yet'
                                : 'No $_filter assignments',
                            style: const TextStyle(
                                fontSize: 15, color: _kBrownSoft),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._filteredAssignments.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _card(a),
                    )),
                  const SizedBox(height: 70),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Dark ship banner =====
  Widget _headerBanner() {
    return Container(
      height: 170,
      decoration: const BoxDecoration(
        color: Color(0xFF241008),
        image: DecorationImage(
          image: NetworkImage('https://i.ibb.co/LwDVRpB/assign.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  'https://i.ibb.co/8g7pqvvr/knot.png',
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
                    const Text('My Assignments',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: ['Times New Roman', 'serif'],
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _kHeaderText,
                        )),
                    const SizedBox(height: 3),
                    Text('$_inspectorName Poojary',
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: ['Times New Roman', 'serif'],
                          fontSize: 15,
                          color: Color(0xFFD9B98F),
                        )),
                  ],
                ),
              ),
              // Online/Offline pill
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                  border:
                  Border.all(color: const Color(0xFFB97A3C), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_online ? Icons.wifi : Icons.wifi_off,
                        color: _online ? const Color(0xFFE0A868) : Colors.grey,
                        size: 14),
                    const SizedBox(width: 6),
                    Text(_online ? 'Online' : 'Offline',
                        style: const TextStyle(
                            color: _kHeaderText,
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

  Widget _howToUse() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _howToOpen = !_howToOpen),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 20, color: _kOrange),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('How to use',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: ['Times New Roman', 'serif'],
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kBrown,
                          ))),
                  Icon(
                      _howToOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: _kBrownSoft),
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
                style: TextStyle(fontSize: 13, color: _kBrownSoft, height: 1.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return Row(
      children: [
        const Text('Filter:',
            style: TextStyle(
                fontSize: 15, color: _kBrown, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kCardBorder),
          ),
          child: DropdownButton<String>(
            value: _filter,
            underline: const SizedBox(),
            dropdownColor: _kCard,
            style: const TextStyle(
                fontSize: 14, color: _kBrown, fontWeight: FontWeight.w700),
            iconEnabledColor: _kBrownSoft,
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
    Color statusBorder;
    if (status == 'upcoming') {
      statusLabel = 'Upcoming';
      statusBg = _kOrangeChip;
      statusFg = _kOrange;
      statusBorder = const Color(0xFFE8C4A6);
    } else if (status == 'in_progress') {
      statusLabel = 'In Progress';
      statusBg = _kOrangeChip;
      statusFg = _kOrange;
      statusBorder = const Color(0xFFE8C4A6);
    } else if (status == 'overdue') {
      statusLabel = 'Overdue';
      statusBg = const Color(0xFFFBE3E0);
      statusFg = const Color(0xFFB03A2E);
      statusBorder = const Color(0xFFEBC0BA);
    } else if (status == 'submitted') {
      statusLabel = 'Completed';
      statusBg = _kGreenChip;
      statusFg = const Color(0xFF5C6B2A);
      statusBorder = const Color(0xFFCBD6A8);
    } else {
      statusLabel = 'Report Ready';
      statusBg = _kGreenChip;
      statusFg = const Color(0xFF5C6B2A);
      statusBorder = const Color(0xFFCBD6A8);
    }

    final bool isSubmitted = status == 'submitted';
    final btnLabel = status == 'upcoming' ? 'Start' : (isSubmitted ? 'Submitted' : 'Resume');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A3A12).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Round ship icon chip
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: _kOrangeChip,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_boat_filled,
                color: Color(0xFF5C3A1E), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                            color: _kBrown,
                          ),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    Text((a['vessel_imo'] ?? '').toString().replaceAll('IMO ', ''),
                        style: const TextStyle(fontSize: 13, color: _kOrange, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: _kBrownSoft),
                    const SizedBox(width: 6),
                    Text(dateStr, style: const TextStyle(fontSize: 13, color: _kBrownSoft)),
                    const SizedBox(width: 16),
                    const Icon(Icons.folder_outlined, size: 15, color: _kBrownSoft),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(a['template'] ?? '—',
                          style: const TextStyle(fontSize: 13, color: _kBrownSoft),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: statusFg)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kCardBorder),
                      ),
                      child: const Text('standard',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _kBrownSoft)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Resume / Start / Submitted button
          Container(
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isSubmitted
                  ? const LinearGradient(colors: [_kGreen, Color(0xFF697930)])
                  : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kOrange, _kOrangeDeep]),
              boxShadow: [
                BoxShadow(
                  color: (isSubmitted ? _kGreen : _kOrangeDeep).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isSubmitted
                    ? null
                    : () async {
                  await InspectionLauncher.open(context, Map<String, dynamic>.from(a));
                  _loadData();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isSubmitted ? Icons.check_circle : Icons.arrow_forward,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(btnLabel,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: ['Times New Roman', 'serif'],
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}