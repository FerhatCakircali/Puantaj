import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/advance.dart';
import 'edit_advance_dialog.dart';
import 'advance_detail_dialog/widgets/advance_detail_header.dart';
import 'advance_detail_dialog/widgets/advance_info_row.dart';
import 'advance_detail_dialog/widgets/advance_action_buttons.dart';
import 'advance_detail_dialog/widgets/advance_deducted_info.dart';
import 'advance_detail_dialog/handlers/advance_delete_handler.dart';
import 'advance_detail_dialog/helpers/currency_formatter_helper.dart';

/// Avans detay dialog'u
class AdvanceDetailDialog extends StatelessWidget {
  final Advance advance;
  final String workerName;
  final VoidCallback onAdvanceUpdated;

  const AdvanceDetailDialog({
    super.key,
    required this.advance,
    required this.workerName,
    required this.onAdvanceUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Advance advance,
    required String workerName,
    required VoidCallback onAdvanceUpdated,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AdvanceDetailDialog(
        advance: advance,
        workerName: workerName,
        onAdvanceUpdated: onAdvanceUpdated,
      ),
    );
  }

  void _editAdvance(BuildContext context) {
    Navigator.pop(context);
    EditAdvanceDialog.show(
      context,
      advance: advance,
      workerName: workerName,
      onAdvanceUpdated: onAdvanceUpdated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    const primaryColor = Color(0xFF4338CA);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(w * 0.06),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdvanceDetailHeader(width: w),
            SizedBox(height: w * 0.06),
            AdvanceInfoRow(
              icon: Icons.person,
              label: 'Çalışan',
              value: workerName,
              width: w,
            ),
            SizedBox(height: w * 0.04),
            AdvanceInfoRow(
              icon: Icons.currency_lira,
              label: 'Tutar',
              value: CurrencyFormatterHelper.formatAmount(advance.amount),
              width: w,
              valueColor: primaryColor,
              valueBold: true,
            ),
            SizedBox(height: w * 0.04),
            AdvanceInfoRow(
              icon: Icons.calendar_today,
              label: 'Tarih',
              value: DateFormat(
                'dd MMMM yyyy',
                'tr_TR',
              ).format(advance.advanceDate),
              width: w,
            ),
            SizedBox(height: w * 0.04),
            AdvanceInfoRow(
              icon: advance.isDeducted ? Icons.check_circle : Icons.pending,
              label: 'Durum',
              value: advance.isDeducted ? 'Düşüldü' : 'Bekliyor',
              width: w,
              valueColor: advance.isDeducted ? Colors.green : Colors.orange,
            ),
            SizedBox(height: w * 0.04),
            if (advance.description != null &&
                advance.description!.isNotEmpty) ...[
              AdvanceInfoRow(
                icon: Icons.description,
                label: 'Açıklama',
                value: advance.description!,
                width: w,
                multiline: true,
              ),
              SizedBox(height: w * 0.04),
            ],
            SizedBox(height: w * 0.02),
            if (!advance.isDeducted)
              AdvanceActionButtons(
                onDelete: () => AdvanceDeleteHandler.deleteAdvance(
                  context,
                  advance: advance,
                  onDeleted: onAdvanceUpdated,
                ),
                onEdit: () => _editAdvance(context),
                width: w,
              )
            else
              AdvanceDeductedInfo(width: w),
          ],
        ),
      ),
    );
  }
}
