import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'assignments_screen.dart';
import 'drafts_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

// ===== RightKnot maritime palette =====
const _kOrange = Color(0xFFF08A3C);      // active icon/text (bright orange)
const _kInactive = Color(0xFFE8D9C0);    // cream inactive icons/text
const _kActiveBox = Color(0xFF7A3A12);   // active tab box fill (warm brown-orange)
const _kActiveBorder = Color(0xFFE8630A);

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(onGoToAssignments: () => setState(() => _currentIndex = 1)),
    const AssignmentsScreen(),
    const DraftsScreen(),
    const HistoryScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.assignment_outlined, Icons.assignment, 'Assignments'),
    _NavItem(Icons.edit_note_outlined, Icons.edit_note, 'Drafts'),
    _NavItem(Icons.history, Icons.history, 'History'),
    _NavItem(Icons.description_outlined, Icons.description, 'Reports'),
    _NavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // Dark brown gradient like the mockup (lighter left, darker right)
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF3A1D0C), Color(0xFF241008)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final selected = _currentIndex == index;
                final item = _navItems[index];
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = index),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: selected
                          ? BoxDecoration(
                        color: _kActiveBox.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _kActiveBorder, width: 1.2),
                      )
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.iconActive : item.icon,
                            color: selected ? _kOrange : _kInactive,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
                              color: selected ? _kOrange : _kInactive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData iconActive;
  final String label;
  const _NavItem(this.icon, this.iconActive, this.label);
}