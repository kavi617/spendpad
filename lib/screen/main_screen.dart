import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  void _goTo(int index) {
    if (index == currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onSeeAll: () => _goTo(1)),
      const HistoryScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(currentIndex),
          child: pages[currentIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(
                height: 1,
                thickness: 0.5,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.6),
              ),
              SizedBox(
                height: 64,
                child: Row(
                  children: [
                    _NavDestination(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: currentIndex == 0,
                      onTap: () => _goTo(0),
                    ),
                    _NavDestination(
                      icon: Icons.receipt_long_rounded,
                      label: 'History',
                      selected: currentIndex == 1,
                      onTap: () => _goTo(1),
                    ),
                    _NavDestination(
                      icon: Icons.insights_rounded,
                      label: 'Insights',
                      selected: currentIndex == 2,
                      onTap: () => _goTo(2),
                    ),
                    _NavDestination(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      selected: currentIndex == 3,
                      onTap: () => _goTo(3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground =
        selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    scale: selected ? 1.08 : 1.0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Icon(
                        icon,
                        key: ValueKey(selected),
                        size: 23,
                        color: foreground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: foreground,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
