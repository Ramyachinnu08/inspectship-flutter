import 'package:flutter/material.dart';
import '../data/mock_store.dart';
import '../models/models.dart';
import 'inspection_screen.dart';

class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 AssignmentsScreen build');
    final all = MockStore.instance.assignments;
    final name = MockStore.instance.inspectorName;
    debugPrint('🟢 Loaded ${all.length} assignments');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: all.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) return _header(name);
            final a = all[i - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _card(context, a),
            );
          },
        ),
      ),
    );
  }

  Widget _header(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
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
                const Text('My Assignments',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                Text('$name Poojary',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A5E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Online',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Assignment a) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr =
        '${a.dueDate.day} ${m[a.dueDate.month - 1]} ${a.dueDate.year}';

    String statusLabel;
    Color statusBg;
    Color statusFg;
    if (a.status == AssignmentStatus.upcoming) {
      statusLabel = 'Upcoming';
      statusBg = const Color(0xFFE0E7FF);
      statusFg = const Color(0xFF3730A3);
    } else if (a.status == AssignmentStatus.inProgress) {
      statusLabel = 'In Progress';
      statusBg = const Color(0xFFE0E7FF);
      statusFg = const Color(0xFF3730A3);
    } else if (a.status == AssignmentStatus.overdue) {
      statusLabel = 'Overdue';
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFF991B1B);
    } else {
      statusLabel = 'Report Ready';
      statusBg = const Color(0xFFE0E7FF);
      statusFg = const Color(0xFF3730A3);
    }

    final btnLabel =
    a.status == AssignmentStatus.upcoming ? 'Start' : 'Resume';

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
                      child: Text(a.vesselName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    Text(a.imo.replaceAll('IMO ', ''),
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 10),
                Text('$dateStr    ${a.templateName}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: statusFg)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(a.scope,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800)),
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
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => InspectionScreen(assignment: a))),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(btnLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2A5E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}