import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'assignments_screen.dart';
import 'drafts_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

const _kPrimary = Color(0xFFFF6B00);

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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final selected = _currentIndex == index;
                final item = _navItems[index];
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.iconActive : item.icon,
                            color: selected ? _kPrimary : const Color(0xFF9CA3AF),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? _kPrimary : const Color(0xFF9CA3AF),
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