import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../utils/formatters/thousands_separator_formatter.dart';
import 'payment_input_field.dart';

/// Ödeme formu alanları widget'ı
///
/// Günlük ücret, gün sayıları ve tutar alanlarını içerir
class PaymentFormFields extends StatelessWidget {
  final bool autoCalculate;
  final int availableFullDays;
  final int availableHalfDays;
  final TextEditingController dailyRateController;
  final TextEditingController fullDaysController;
  final TextEditingController halfDaysController;
  final TextEditingController amountController;
  final FocusNode dailyRateFocus;
  final FocusNode fullDaysFocus;
  final FocusNode halfDaysFocus;
  final FocusNode amountFocus;
  final GlobalKey dailyRateKey;
  final GlobalKey fullDaysKey;
  final GlobalKey halfDaysKey;
  final GlobalKey amountKey;
  final ValueChanged<String>? onFullDaysChanged;
  final ValueChanged<String>? onHalfDaysChanged;

  const PaymentFormFields({
    super.key,
    required this.autoCalculate,
    required this.availableFullDays,
    required this.availableHalfDays,
    required this.dailyRateController,
    required this.fullDaysController,
    required this.halfDaysController,
    required this.amountController,
    required this.dailyRateFocus,
    required this.fullDaysFocus,
    required this.halfDaysFocus,
    required this.amountFocus,
    required this.dailyRateKey,
    required this.fullDaysKey,
    required this.halfDaysKey,
    required this.amountKey,
    this.onFullDaysChanged,
    this.onHalfDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (autoCalculate) ...[
          Container(
            key: dailyRateKey,
            child: PaymentInputField(
              icon: Icons.currency_lira,
              label: 'Günlük Ücret',
              hint: '0',
              controller: dailyRateController,
              focusNode: dailyRateFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (availableFullDays > 0) ...[
          Container(
            key: fullDaysKey,
            child: PaymentInputField(
              icon: Icons.wb_sunny_outlined,
              label: 'Tam Gün Sayısı',
              hint: 'Maks: $availableFullDays',
              controller: fullDaysController,
              focusNode: fullDaysFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onFullDaysChanged,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (availableHalfDays > 0) ...[
          Container(
            key: halfDaysKey,
            child: PaymentInputField(
              icon: Icons.wb_twilight_outlined,
              label: 'Yarım Gün Sayısı',
              hint: 'Maks: $availableHalfDays',
              controller: halfDaysController,
              focusNode: halfDaysFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onHalfDaysChanged,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_shouldShowAmountField()) ...[
          Container(
            key: amountKey,
            child: PaymentInputField(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Ödenecek Miktar',
              hint: '0',
              controller: amountController,
              focusNode: amountFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  bool _shouldShowAmountField() {
    final fullDays = int.tryParse(fullDaysController.text) ?? 0;
    final halfDays = int.tryParse(halfDaysController.text) ?? 0;
    return fullDays > 0 || halfDays > 0;
  }
}
