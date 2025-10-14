import 'package:flutter/material.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: index,
        onTap: onChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF00BCD4), // Turquesa
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 11,
        ),
        showUnselectedLabels: true,
        elevation: 0,
        items: items
            .map((e) => BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(e.icon, size: 24),
                  ),
                  label: e.label,
                ))
            .toList(),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.label,
  });
}
