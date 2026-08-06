import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'dashboard_screen.dart';
import 'assignments_screen.dart';
import 'drafts_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _labels = [
    'Dashboard',
    'Assignments',
    'Drafts',
    'History',
    'Reports',
    'Profile',
  ];
  static const _icons = [
    Icons.dashboard_outlined,
    Icons.assignment_outlined,
    Icons.edit_note_outlined,
    Icons.history_outlined,
    Icons.description_outlined,
    Icons.person_outline,
  ];
  static const _iconsSel = [
    Icons.dashboard,
    Icons.assignment,
    Icons.edit_note,
    Icons.history,
    Icons.description,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onGoToAssignments: () => setState(() => _index = 1)),
      const AssignmentsScreen(),
      const DraftsScreen(),
      const HistoryScreen(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    final useRail =
        Responsive.isTablet(context) && Responsive.isLandscape(context);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: Colors.white,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.navy.withValues(alpha: .12),
              selectedIconTheme:
              const IconThemeData(color: AppColors.navy),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: AppColors.signal,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.anchor,
                      color: Colors.white, size: 24),
                ),
              ),
              destinations: List.generate(
                _labels.length,
                    (i) => NavigationRailDestination(
                  icon: Icon(_icons[i]),
                  selectedIcon: Icon(_iconsSel[i]),
                  label: Text(_labels[i]),
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: AppColors.line),
            Expanded(child: pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: List.generate(
          _labels.length,
              (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_iconsSel[i]),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}