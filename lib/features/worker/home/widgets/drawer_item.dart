import 'package:flutter/material.dart';

/// Modern Worker Drawer menü öğesi - Minimal tasarım
class WorkerHomeScreenDrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const WorkerHomeScreenDrawerItem({
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ListTile(
      leading: Icon(
        icon,
        color:
            iconColor ??
            (isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant),
        size: screenWidth * 0.07,
      ),
      title: Text(
        text,
        style: TextStyle(
          color:
              textColor ??
              (isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: screenWidth * 0.042,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      selected: isSelected,
      selectedTileColor: Colors.transparent,
    );
  }
}
