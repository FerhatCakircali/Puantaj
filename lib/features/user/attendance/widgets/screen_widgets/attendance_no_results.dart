import 'package:flutter/material.dart';

/// Arama sonucu bulunamadığında gösterilen widget
class AttendanceNoResults extends StatelessWidget {
  const AttendanceNoResults({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final fontSize = isTablet ? 22.0 : 16.0;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: SizedBox(
        height: screenHeight * 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Arama sonucu bulunamadı.',
                style: TextStyle(fontSize: fontSize, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
