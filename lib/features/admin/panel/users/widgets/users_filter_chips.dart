import 'package:flutter/material.dart';
import '../../widgets/user_filter_chip.dart';

/// Kullanıcı filtre chip'leri
class UsersFilterChips extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;
  final int userCount;

  const UsersFilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.userCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          UserFilterChip(
            label: 'Tümü',
            value: 'all',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
          ),
          const SizedBox(width: 8),
          UserFilterChip(
            label: 'Aktif',
            value: 'active',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
          ),
          const SizedBox(width: 8),
          UserFilterChip(
            label: 'Bloklu',
            value: 'blocked',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
          ),
          const SizedBox(width: 8),
          UserFilterChip(
            label: 'Admin',
            value: 'admin',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$userCount kullanıcı',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
