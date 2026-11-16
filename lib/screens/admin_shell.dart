import 'package:flutter/material.dart';

import 'enrollments_screen.dart';
import 'grades_screen.dart';
import 'schedules_screen.dart';
import 'students_screen.dart';
import 'subjects_screen.dart';

// one tab per table; side rail on wide screens, bottom bar on phones
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _items = [
    (icon: Icons.people_outline, selected: Icons.people, label: 'Students'),
    (icon: Icons.menu_book_outlined, selected: Icons.menu_book, label: 'Subjects'),
    (icon: Icons.calendar_month_outlined, selected: Icons.calendar_month, label: 'Schedules'),
    (icon: Icons.how_to_reg_outlined, selected: Icons.how_to_reg, label: 'Enrollments'),
    (icon: Icons.grade_outlined, selected: Icons.grade, label: 'Grades'),
  ];

  Widget _page() => switch (_index) {
        0 => const StudentsScreen(),
        1 => const SubjectsScreen(),
        2 => const SchedulesScreen(),
        3 => const EnrollmentsScreen(),
        _ => const GradesScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      appBar: AppBar(title: Text('Registrar  |  ${_items[_index].label}')),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _index,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in _items)
                  NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: Text(d.label)),
              ],
            ),
          Expanded(child: KeyedSubtree(key: ValueKey(_index), child: _page())),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in _items) NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: d.label),
              ],
            ),
    );
  }
}
