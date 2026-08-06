import 'package:flutter/material.dart';
import '../data/mock_store.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'inspection_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onGoToAssignments;
  const DashboardScreen({super.key, required this.onGoToAssignments});

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

  @override
  Widget build(BuildContext context) {
    final s = MockStore.instance;
    final tablet = Responsive.isTablet(context);

    Assignment? resumeCandidate;
    for (final a in s.assignments) {
      if (a.status == AssignmentStatus.inProgress) {
        resumeCandidate = a;
        break;
      }
    }

    final today = s.pending.where((a) => _isToday(a.dueDate)).toList();
    final assignedToday = s.assignments
        .where((a) =>
    _isToday(a.dueDate) && a.status != AssignmentStatus.submitted)
        .length;

    return Scaffold(
      backgroundColor: AppColors.foam,
      body: SafeArea(
        child: ConstrainedContent(
          child: ListView(
            padding: EdgeInsets.symmetric(
                horizontal: Responsive.pagePad(context)),
            children: [
              const SizedBox(height: 14),
              _Header(name: s.inspectorName, greeting: _greeting()),
              const SizedBox(height: 22),
              _StatRow(
                cards: [
                  _StatData(
                      icon: Icons.assignment_outlined,
                      value: assignedToday,
                      label: 'Assigned Today',
                      color: AppColors.navy),
                  _StatData(
                      icon: Icons.play_arrow_rounded,
                      value: s.inProgressCount,
                      label: 'In Progress',
                      color: AppColors.signal),
                  _StatData(
                      icon: Icons.sync,
                      value: s.pendingSyncCount,
                      label: 'Pending Sync',
                      color: AppColors.nv),
                  _StatData(
                      icon: Icons.description_outlined,
                      value: s.reportsReadyCount,
                      label: 'Reports Ready',
                      color: AppColors.pass),
                ],
                tablet: tablet,
              ),
              const SizedBox(height: 22),
              if (resumeCandidate != null) ...[
                _ResumeBanner(assignment: resumeCandidate),
                const SizedBox(height: 22),
              ],
              // Today's Assignments
              Row(
                children: [
                  const Text('Today\'s Assignments',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(
                    onPressed: onGoToAssignments,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.inkSoft,
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Row(children: [
                      Text('View all'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 15),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (today.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  alignment: Alignment.center,
                  child: const Text(
                    'No assignments for today.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 14),
                  ),
                )
              else
                ...today.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AssignmentCard(assignment: a),
                )),
              const SizedBox(height: 22),
              // Offline Drafts
              if (s.drafts.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                          color: AppColors.signal, shape: BoxShape.circle),
                      child: const Icon(Icons.priority_high,
                          size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text('Offline Drafts',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.inkSoft,
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: const Row(children: [
                        Text('Fix & Sync'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 15),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...s.drafts.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DraftRow(assignment: a),
                )),
                const SizedBox(height: 22),
              ],
              // Recent Reports
              if (s.submitted.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('Recent Reports',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.inkSoft,
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: const Row(children: [
                        Text('View all'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 15),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...s.submitted.take(4).map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReportRow(assignment: a),
                )),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String name;
  final String greeting;
  const _Header({required this.name, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$greeting, $name',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                  overflow: TextOverflow.ellipsis),
              const Text('Here\'s your day at a glance',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi, size: 12, color: Colors.white),
              SizedBox(width: 6),
              Text('Online',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stat cards row ───────────────────────────────────────────────────
class _StatData {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  _StatData(
      {required this.icon,
        required this.value,
        required this.label,
        required this.color});
}

class _StatRow extends StatelessWidget {
  final List<_StatData> cards;
  final bool tablet;
  const _StatRow({required this.cards, required this.tablet});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final oneRow = width >= 560;
    if (oneRow) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: _StatCard(data: cards[i])),
            if (i < cards.length - 1) const SizedBox(width: 12),
          ]
        ],
      );
    }
    return Column(
      children: [
        Row(children: [
          Expanded(child: _StatCard(data: cards[0])),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(data: cards[1])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard(data: cards[2])),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(data: cards[3])),
        ]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(data.icon, size: 22, color: data.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${data.value}',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(data.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resume Last Inspection banner ────────────────────────────────────
class _ResumeBanner extends StatelessWidget {
  final Assignment assignment;
  const _ResumeBanner({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.signal.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.signal.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.signal.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_boat_filled,
                color: AppColors.signal, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Resume Last Inspection',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(assignment.vesselName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
                Text(assignment.templateName,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkSoft),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => InspectionScreen(assignment: assignment))),
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text('Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.signal,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today assignment card ────────────────────────────────────────────
class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  const _AssignmentCard({required this.assignment});

  ({Color bg, Color fg, String label}) _statusStyle() {
    switch (assignment.status) {
      case AssignmentStatus.upcoming:
        return (
        bg: AppColors.navy.withValues(alpha: .10),
        fg: AppColors.navy,
        label: 'Upcoming'
        );
      case AssignmentStatus.inProgress:
        return (
        bg: AppColors.signal.withValues(alpha: .15),
        fg: AppColors.signal,
        label: 'In Progress'
        );
      case AssignmentStatus.overdue:
        return (
        bg: AppColors.fail.withValues(alpha: .12),
        fg: AppColors.fail,
        label: 'Overdue'
        );
      case AssignmentStatus.submitted:
        return (
        bg: AppColors.pass.withValues(alpha: .12),
        fg: AppColors.pass,
        label: 'Submitted'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final st = _statusStyle();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => InspectionScreen(assignment: a))),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.directions_boat_filled,
                    color: AppColors.navy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.vesselName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis),
                    Text(a.imo,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: st.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(st.label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: st.fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Offline draft row ────────────────────────────────────────────────
class _DraftRow extends StatelessWidget {
  final Assignment assignment;
  const _DraftRow({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => InspectionScreen(assignment: assignment))),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.signal.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sync,
                    color: AppColors.signal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.vesselName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis),
                    Text('answers',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.inkSoft.withValues(alpha: .8))),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.signal.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.signal.withValues(alpha: .30)),
                ),
                child: const Text('Queued',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.signal)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent Reports row ───────────────────────────────────────────────
class _ReportRow extends StatelessWidget {
  final Assignment assignment;
  const _ReportRow({required this.assignment});

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.description_outlined,
                    color: AppColors.navy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.vesselName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis),
                    Text(_formatDate(assignment.dueDate),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.pass.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Ready',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pass)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}