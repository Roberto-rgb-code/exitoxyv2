import 'package:flutter/material.dart';

class BottomNavItem {
  final IconData icon;
  final String label;
  const BottomNavItem({required this.icon, required this.label});
}

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<BottomNavItem> items;

  const BottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onChanged,
      destinations: [
        for (final it in items)
          NavigationDestination(
            icon: Icon(it.icon),
            label: it.label,
          ),
      ],
    );
  }
}
