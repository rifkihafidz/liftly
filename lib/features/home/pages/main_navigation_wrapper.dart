import 'package:flutter/material.dart';
import '../../session/pages/workout_history_page.dart';
import '../../plans/pages/plans_page.dart';
import '../../settings/pages/settings_page.dart';
import 'home_page.dart';
import '../../../core/constants/colors.dart';

import 'dart:async';
import '../../../core/services/backup_service.dart';
import '../../stats/pages/stats_page.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => MainNavigationWrapperState();
}

class MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for auto-signin errors
    final backupService = BackupService();

    // Check for any existing error first
    if (backupService.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(backupService.lastError!);
      });
    }

    _errorSubscription = backupService.onError.listen((message) {
      if (mounted) {
        _showErrorSnackBar(message);
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Copy',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Copy to clipboard if needed, for now just dismiss
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  void setIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomePage(),
      const WorkoutHistoryPage(),
      const StatsPage(),
      const PlansPage(),
      const SettingsPage(),
    ];

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    // Safety check to prevent index out of bounds
    final int safeIndex = _selectedIndex < pages.length ? _selectedIndex : 0;

    return PopScope(
      canPop: safeIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setIndex(0);
      },
      child: Scaffold(
        body: pages[safeIndex],
        bottomNavigationBar: isMobile && safeIndex != 0
            ? Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.borderDark.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppColors.darkBg,
                  selectedItemColor: AppColors.accent,
                  unselectedItemColor:
                      AppColors.textSecondary.withValues(alpha: 0.6),
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.fitness_center_rounded),
                      activeIcon: Icon(Icons.fitness_center_rounded),
                      label: 'Workout',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history_rounded),
                      activeIcon: Icon(Icons.history_rounded),
                      label: 'History',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bar_chart_rounded),
                      activeIcon: Icon(Icons.bar_chart_rounded),
                      label: 'Stats',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bookmarks_rounded),
                      activeIcon: Icon(Icons.bookmarks_rounded),
                      label: 'Plans',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_rounded),
                      activeIcon: Icon(Icons.settings_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
