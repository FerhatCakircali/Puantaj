import 'package:flutter/material.dart';

/// Çalışan olmadığında gösterilen boş durum widget'ı
class AttendanceEmptyState extends StatelessWidget {
  const AttendanceEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final fontSize = isTablet ? 22.0 : 16.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz çalışan eklenmemiş.',
            style: TextStyle(fontSize: fontSize, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
