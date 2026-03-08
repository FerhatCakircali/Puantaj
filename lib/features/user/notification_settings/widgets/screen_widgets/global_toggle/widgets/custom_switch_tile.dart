import 'package:flutter/material.dart';
import '../helpers/theme_helper.dart';

/// Özelleştirilmiş switch tile widget'ı
///
/// Tutarlı görünüm ve davranış için kullanılır.
class CustomSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? secondary;

  const CustomSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: colorScheme.primary,
      inactiveThumbColor: ThemeHelper.getSwitchInactiveThumbColor(context),
      inactiveTrackColor: ThemeHelper.getSwitchInactiveTrackColor(context),
      trackOutlineColor: ThemeHelper.getSwitchTrackOutlineColor(context),
      secondary: secondary,
    );
  }
}
