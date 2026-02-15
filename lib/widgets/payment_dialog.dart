import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/employee.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';

class PaymentDialog extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.employee,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _paymentService = PaymentService();
  final _authService = AuthService();
  final _fullDaysController = TextEditingController();
  final _halfDaysController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = true;
  int _availableFullDays = 0;
  int _availableHalfDays = 0;

  @override
  void initState() {
    super.initState();
    _loadUnpaidDays();
  }

  @override
  void dispose() {
    _fullDaysController.dispose();
    _halfDaysController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUnpaidDays() async {
    setState(() => _isLoading = true);
    final unpaidDays = await _paymentService.getUnpaidDays(widget.employee.id);
    setState(() {
      _availableFullDays = unpaidDays['fullDays'] ?? 0;
      _availableHalfDays = unpaidDays['halfDays'] ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _makePayment() async {
    final fullDays = int.tryParse(_fullDaysController.text) ?? 0;
    final halfDays = int.tryParse(_halfDaysController.text) ?? 0;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (fullDays > _availableFullDays || halfDays > _availableHalfDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Girdiğiniz gün sayısı mevcut gün sayısından fazla olamaz.',
          ),
        ),
      );
      return;
    }

    if (fullDays == 0 && halfDays == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir gün seçmelisiniz.')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir ödeme miktarı girin.'),
        ),
      );
      return;
    }

    final currentUser = await _authService.currentUser;
    if (currentUser == null) return;

    final payment = Payment(
      userId: currentUser['id'] as int,
      workerId: widget.employee.id,
      fullDays: fullDays,
      halfDays: halfDays,
      paymentDate: DateTime.now(),
      amount: amount,
    );

    await _paymentService.addPayment(payment);
    if (mounted) {
      Navigator.pop(context);
      widget.onPaymentComplete();
    }
  }

  bool _shouldShowAmountField() {
    final fullDays = int.tryParse(_fullDaysController.text) ?? 0;
    final halfDays = int.tryParse(_halfDaysController.text) ?? 0;
    return fullDays > 0 || halfDays > 0;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 32.0 : 16.0;
    final fontSize = isTablet ? 18.0 : 14.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: isTablet ? 600 : double.infinity,
        padding: EdgeInsets.all(padding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.7),
                        child: Text(
                          widget.employee.name.isNotEmpty
                              ? widget.employee.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.employee.name,
                            style: TextStyle(
                              fontSize: fontSize * 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.employee.title.isNotEmpty)
                            Text(
                              widget.employee.title,
                              style: TextStyle(
                                fontSize: fontSize,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Kapat',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Çalıştığı Tam Gün: ',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$_availableFullDays',
                          style: TextStyle(
                            fontSize: fontSize,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Çalıştığı Yarım Gün: ',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$_availableHalfDays',
                          style: TextStyle(
                            fontSize: fontSize,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_availableFullDays > 0) ...[
                      TextField(
                        controller: _fullDaysController,
                        decoration: InputDecoration(
                          labelText: 'Tam Gün Sayısı',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.event,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_availableHalfDays > 0) ...[
                      TextField(
                        controller: _halfDaysController,
                        decoration: InputDecoration(
                          labelText: 'Yarım Gün Sayısı',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.event_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.7),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_shouldShowAmountField()) ...[
                      TextField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Ödenecek Miktar',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              '₺',
                              style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^[0-9]*[.,]?[0-9]*'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _makePayment,
                        icon: const Icon(Icons.check),
                        label: const Text('Ödeme Yap'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
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
