import 'package:flutter/material.dart';

/// Düşülmüş avans bilgilendirme widget'ı
class AdvanceDeductedInfo extends StatelessWidget {
  final double width;

  const AdvanceDeductedInfo({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.green, size: width * 0.05),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Text(
              'Bu avans ödemeden düşülmüştür. Düzenleme ve silme işlemi yapılamaz.',
              style: TextStyle(
                fontSize: width * 0.035,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
