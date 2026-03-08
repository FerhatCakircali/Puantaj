import 'package:flutter/material.dart';
import '../widgets/payment_empty_state.dart';
import '../widgets/payment_card.dart';

/// Ödeme geçmişi tab widget'ı
class WorkerPaymentTab extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> paymentHistory;
  final VoidCallback onRefresh;

  const WorkerPaymentTab({
    super.key,
    required this.isLoading,
    required this.paymentHistory,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    const primaryColor = Color(0xFF4338CA);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (paymentHistory.isEmpty) {
      return const PaymentEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.015, w * 0.06, h * 0.1),
        itemCount: paymentHistory.length,
        itemExtent: h * 0.21,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: h * 0.015),
            child: PaymentCard(payment: paymentHistory[index]),
          );
        },
      ),
    );
  }
}
