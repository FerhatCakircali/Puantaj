import 'package:flutter/material.dart';

/// Avans açıklama bilgisini gösteren widget
class PaymentAdvanceInfo extends StatelessWidget {
  final String? description;

  const PaymentAdvanceInfo({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    if (description == null || description!.isEmpty) {
      return _buildEmptyDescription(w, h, theme);
    }

    return _buildDescription(w, h, theme);
  }

  Widget _buildEmptyDescription(double w, double h, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.01),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: w * 0.04,
            color: Colors.orange.withValues(alpha: 0.7),
          ),
          SizedBox(width: w * 0.02),
          Text(
            'Açıklama eklenmemiş',
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(double w, double h, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.01),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            size: w * 0.04,
            color: Colors.orange,
          ),
          SizedBox(width: w * 0.02),
          Expanded(
            child: Text(
              description!,
              style: TextStyle(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
