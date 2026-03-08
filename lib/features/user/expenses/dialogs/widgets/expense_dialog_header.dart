import 'package:flutter/material.dart';
import '../constants/expense_dialog_constants.dart';

/// Masraf dialog başlık widget'ı
///
/// Icon, başlık ve kapat butonu içerir.
class ExpenseDialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onClose;

  const ExpenseDialogHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.03),
          decoration: BoxDecoration(
            color: ExpenseDialogConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              ExpenseDialogConstants.iconBorderRadius,
            ),
          ),
          child: Icon(
            icon,
            color: ExpenseDialogConstants.primaryColor,
            size: w * 0.06,
          ),
        ),
        SizedBox(width: w * 0.03),
        Text(
          title,
          style: TextStyle(
            fontSize: w * 0.05,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
      ],
    );
  }
}
