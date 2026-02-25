import 'package:flutter/material.dart';

/// Modern Drawer menü öğesi
/// Kullanıcılar panelindeki tasarıma uygun
class HomeScreenDrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final int index;
  final int? selectedIndex;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const HomeScreenDrawerItem({
    super.key,
    required this.icon,
    required this.text,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              iconColor ??
              (isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          size: 24,
        ),
        title: Text(
          text,
          style: TextStyle(
            color:
                textColor ??
                (isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
