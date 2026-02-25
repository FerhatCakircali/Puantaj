import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../screens/constants/colors.dart';

/// Çalışan ödeme kartı - Performanslı ve temiz tasarım
class EmployeePaymentCard extends StatelessWidget {
  final Employee employee;
  final Map<String, int> unpaidDays;
  final double unpaidScore;
  final VoidCallback onTap;
  final bool isTablet;

  const EmployeePaymentCard({
    super.key,
    required this.employee,
    required this.unpaidDays,
    required this.unpaidScore,
    required this.onTap,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fontSize = isTablet ? 20.0 : 16.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryIndigo,
                      primaryIndigo.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    employee.name.isNotEmpty
                        ? employee.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Employee Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      employee.name,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (employee.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        employee.title,
                        style: TextStyle(
                          fontSize: fontSize * 0.875,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Unpaid Days Info
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: colorScheme.error,
                        ),
                        Text(
                          '${unpaidDays['fullDays']} tam, ${unpaidDays['halfDays']} yarım',
                          style: TextStyle(
                            fontSize: fontSize * 0.875,
                            color: colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${unpaidScore.toStringAsFixed(1)} gün',
                            style: TextStyle(
                              fontSize: fontSize * 0.75,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
