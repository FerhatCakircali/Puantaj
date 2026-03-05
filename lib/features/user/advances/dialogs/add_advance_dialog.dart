import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../models/employee.dart';
import '../../../../models/advance.dart';
import '../controllers/advance_controller.dart';
import '../../../../utils/currency_input_formatter.dart';

/// Avans ekleme dialog'u
class AddAdvanceDialog extends StatefulWidget {
  final List<Employee> employees;
  final VoidCallback onAdvanceAdded;

  const AddAdvanceDialog({
    super.key,
    required this.employees,
    required this.onAdvanceAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Employee> employees,
    required VoidCallback onAdvanceAdded,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddAdvanceDialog(
        employees: employees,
        onAdvanceAdded: onAdvanceAdded,
      ),
    );
  }

  @override
  State<AddAdvanceDialog> createState() => _AddAdvanceDialogState();
}

class _AddAdvanceDialogState extends State<AddAdvanceDialog> {
  final AdvanceController _controller = AdvanceController();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Employee? _selectedEmployee;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  static const Color primaryColor = Color(0xFF4338CA);

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

  Future<void> _saveAdvance() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir çalışan seçin')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final advance = Advance(
        id: null, // Supabase otomatik oluşturacak
        userId: 0, // Service katmanında set edilecek
        workerId: _selectedEmployee!.id,
        amount: double.parse(_amountController.text.replaceAll('.', '')),
        advanceDate: _selectedDate,
        description: _descriptionController.text.trim(),
        isDeducted: false,
        deductedFromPaymentId: null,
      );

      await _controller.addAdvance(advance);

      if (!mounted) return;

      Navigator.of(context).pop();
      widget.onAdvanceAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_selectedEmployee!.name} için avans eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Avans ekleme hatası: $e');

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
        constraints: BoxConstraints(maxWidth: 500),
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
                      Icons.account_balance_wallet,
                      color: primaryColor,
                      size: w * 0.06,
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Text(
                    'Avans Ekle',
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

              // Çalışan seçimi
              Text(
                'Çalışan',
                style: TextStyle(
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: w * 0.02),
              DropdownButtonFormField<Employee>(
                value: _selectedEmployee,
                decoration: InputDecoration(
                  hintText: 'Çalışan seçin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: w * 0.035,
                  ),
                ),
                items: widget.employees.map((emp) {
                  return DropdownMenuItem(value: emp, child: Text(emp.name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEmployee = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Çalışan seçin';
                  return null;
                },
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
                  // Noktaları temizle ve parse et
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
                      onPressed: _isLoading ? null : _saveAdvance,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
