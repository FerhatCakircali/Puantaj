import 'package:flutter/material.dart';

/// Rapor ekranı tab bar widget'ı
///
/// Çalışan ve Dönemsel rapor sekmelerini gösterir.
class ReportTabBar extends StatelessWidget {
  final TabController controller;

  const ReportTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const padding = 24.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(padding, 16, padding, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: controller,
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.people, size: 20), text: 'Çalışan'),
          Tab(icon: Icon(Icons.calendar_month, size: 20), text: 'Dönemsel'),
        ],
      ),
    );
  }
}
