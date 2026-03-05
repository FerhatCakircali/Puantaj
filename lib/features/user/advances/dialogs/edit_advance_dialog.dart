import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../models/advance.dart';
import '../controllers/advance_controller.dart';
import '../../../../utils/currency_input_formatter.dart';

/// Avans düzenleme dialog'u
class EditAdvanceDialog extends StatefulWidget {
  final Advance advance;
  final String workerName;
  final VoidCallback onAdvanceUpdated;

  const EditAdvanceDialog({
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
      builder: (context) => EditAdvanceDialog(
        advance: advance,
        workerName: workerName,
        onAdvanceUpdated: onAdvanceUpdated,
      ),
    );
  }

  @override
  State<EditAdvanceDialog> createState() => _EditAdvanceDialogState();
}

class _EditAdvanceDialogState extends State<EditAdvanceDialog> {
  final AdvanceController _controller = AdvanceController();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  late DateTime _selectedDate;
  bool _isLoading = false;

  static const Color primaryColor = Color(0xFF4338CA);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.advance.amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      ),
    );
    _descriptionController = TextEditingController(
      text: widget.advance.description ?? '',
    );
    _selectedDate = widget.advance.advanceDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateAdvance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedAdvance = widget.advance.copyWith(
        amount: double.parse(_amountController.text.replaceAll('.', '')),
        advanceDate: _selectedDate,
        description: _descriptionController.text.trim(),
      );

      await _controller.updateAdvance(updatedAdvance);

      if (!mounted) return;

      Navigator.of(context).pop();
      widget.onAdvanceUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Avans güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Avans güncelleme hatası: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(w * 0.06),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(w * 0.03),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: primaryColor,
                        size: w * 0.06,
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Text(
                      'Avans Düzenle',
                      style: TextStyle(
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.06),

                // Çalışan (sadece gösterim)
                Text(
                  'Çalışan',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: w * 0.02),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: w * 0.035,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    widget.workerName,
                    style: TextStyle(
                      fontSize: w * 0.04,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: w * 0.04),

                // Tutar
                Text(
                  'Tutar (₺)',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: w * 0.02),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: '₺ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: w * 0.035,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tutar girin';
                    }
                    final cleanValue = value.replaceAll('.', '');
                    final amount = double.tryParse(cleanValue);
                    if (amount == null || amount <= 0) {
                      return 'Geçerli bir tutar girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: w * 0.04),

                // Tarih
                Text(
                  'Tarih',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: w * 0.02),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: w * 0.035,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey.shade600),
                        SizedBox(width: w * 0.03),
                        Text(
                          DateFormat(
                            'dd MMMM yyyy',
                            'tr_TR',
                          ).format(_selectedDate),
                          style: TextStyle(
                            fontSize: w * 0.04,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: w * 0.04),

                // Açıklama
                Text(
                  'Açıklama (Opsiyonel)',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: w * 0.02),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Avans açıklaması...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: w * 0.035,
                    ),
                  ),
                ),
                SizedBox(height: w * 0.06),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: w * 0.035),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('İptal'),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateAdvance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: w * 0.035),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: w * 0.05,
                                width: w * 0.05,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Güncelle'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
