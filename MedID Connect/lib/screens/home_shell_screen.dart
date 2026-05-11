import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import 'dashboard_screen.dart';
import 'lab_results_screen.dart';
import 'medical_records_screen.dart';
import 'medical_timeline_screen.dart';
import 'profile_settings_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  static const String route = '/home';

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
          onOpenTab: (index) => setState(() => _selectedIndex = index)),
      const MedicalRecordsScreen(),
      const MedicalTimelineScreen(),
      const LabResultsScreen(),
      const ProfileSettingsScreen(),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_rounded),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_rounded),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Labs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
