import 'package:flutter/material.dart';
import '../../../../../widgets/common_button.dart';

class ReminderActionButtons extends StatelessWidget {
  final bool isDeleting;
  final VoidCallback onConfirm;

  const ReminderActionButtons({
    super.key,
    required this.isDeleting,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return CommonButton(
      onPressed: isDeleting ? () {} : onConfirm,
      label: 'Tamam',
      icon: Icons.check,
      isLoading: isDeleting,
    );
  }
}
