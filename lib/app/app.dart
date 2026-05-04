import 'package:flutter/material.dart';
import 'package:hand_track/features/history/presentation/history_screen.dart';
import 'package:hand_track/features/progress/presentation/progress_screen.dart';
import 'package:hand_track/features/settings/presentation/settings_screen.dart';
import 'package:hand_track/features/sessions/presentation/home_screen.dart';

class HandTrackAppShell extends StatefulWidget {
  const HandTrackAppShell({super.key});

  @override
  State<HandTrackAppShell> createState() => _HandTrackAppShellState();
}

class _HandTrackAppShellState extends State<HandTrackAppShell> {
  int _currentIndex = 0;

  static const _titles = <String>['Session', 'History', 'Progress', 'Settings'];

  final _screens = const <Widget>[
    HomeScreen(),
    HistoryScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.flash_on_outlined),
            selectedIcon: Icon(Icons.flash_on),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
