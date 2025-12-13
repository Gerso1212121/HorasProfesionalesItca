import 'package:flutter/material.dart';

// --- Configuration & Theme ---
class NavBarConfig {
  static const double height = 86.0;
  static const double fabSize = 64.0;
  static const double fabSelectedSize = 68.0;
  static const double borderRadius = 24.0;
  static const double iconSizeActive = 26.0;
  static const double iconSizeInactive = 24.0;

  // Colors
  static const Color primary = Color(0xFFF66B7D);
  static const Color accent = Color(0xFFFF8E9E);
  static const Color inactiveIcon = Color(0xFFA0AEC0);
  static const Color inactiveLabel = Color(0xFF718096);
  static const Color background = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x1A000000);
}

// --- Data Model ---
class NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// --- Main Widget ---
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItemData> items;

  CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    List<NavItemData>? items,
  }) : items = items ?? _defaultItems;

  static const List<NavItemData> _defaultItems = [
    NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home_filled, label: 'Inicio'),
    NavItemData(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Diario'),
    NavItemData(icon: Icons.fitness_center_outlined, activeIcon: Icons.fitness_center, label: 'Ejercicios'),
    NavItemData(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final int middleIndex = (items.length / 2).floor();

    return SizedBox(
      height: NavBarConfig.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // --- Background ---
          Container(
            height: NavBarConfig.height,
            decoration: BoxDecoration(
              color: NavBarConfig.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(NavBarConfig.borderRadius),
              ),
              boxShadow: const [
                BoxShadow(
                  color: NavBarConfig.shadow,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
          ),

          // --- Nav Items ---
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildNavItems(middleIndex),
            ),
          ),

          // --- Indicator ---
          Positioned(
            top: 6,
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: NavBarConfig.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // --- FAB central ---
          Positioned(
            bottom: 28, // Sin crear espacio extra
            child: _AssistantFAB(
              isSelected: currentIndex == middleIndex,
              onTap: () => onTap(middleIndex),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems(int middleIndex) {
    final List<Widget> widgets = [];

    for (int i = 0; i < items.length; i++) {
      if (i == middleIndex) {
        widgets.add(SizedBox(width: NavBarConfig.fabSize - 20)); // más compacto
      }

      final int logicalIndex = i >= middleIndex ? i + 1 : i;

      widgets.add(
        _NavBarItem(
          data: items[i],
          isSelected: currentIndex == logicalIndex,
          onTap: () => onTap(logicalIndex),
        ),
      );
    }

    return widgets;
  }
}

// --- Item del Navbar ---
class _NavBarItem extends StatelessWidget {
  final NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 54, // MÁS JUNTO
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(6), // más compacto
              decoration: BoxDecoration(
                color: isSelected
                    ? NavBarConfig.primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected ? data.activeIcon : data.icon,
                size: isSelected
                    ? NavBarConfig.iconSizeActive
                    : NavBarConfig.iconSizeInactive,
                color: isSelected
                    ? NavBarConfig.primary
                    : NavBarConfig.inactiveIcon,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? NavBarConfig.primary
                    : NavBarConfig.inactiveLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- FAB Central ---
class _AssistantFAB extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _AssistantFAB({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size =
        isSelected ? NavBarConfig.fabSelectedSize : NavBarConfig.fabSize;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [NavBarConfig.primary, NavBarConfig.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: NavBarConfig.primary.withOpacity(
                isSelected ? 0.42 : 0.28,
              ),
              blurRadius: isSelected ? 22 : 16,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assistant, color: Colors.white, size: 28),
              SizedBox(height: 2),
              Text(
                'AI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
