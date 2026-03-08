import 'package:flutter/material.dart';

/// Ödeme dialog'u için focus yönetimi helper'ı
class PaymentFocusHelper {
  final ScrollController scrollController;
  final FocusNode dailyRateFocus;
  final FocusNode fullDaysFocus;
  final FocusNode halfDaysFocus;
  final FocusNode amountFocus;

  PaymentFocusHelper({
    required this.scrollController,
    required this.dailyRateFocus,
    required this.fullDaysFocus,
    required this.halfDaysFocus,
    required this.amountFocus,
  });

  /// Focus listener'ları ayarlar
  void setupListeners({
    required GlobalKey dailyRateKey,
    required GlobalKey fullDaysKey,
    required GlobalKey halfDaysKey,
    required GlobalKey amountKey,
  }) {
    dailyRateFocus.addListener(() {
      if (dailyRateFocus.hasFocus) _ensureVisible(dailyRateKey);
    });
    fullDaysFocus.addListener(() {
      if (fullDaysFocus.hasFocus) _ensureVisible(fullDaysKey);
    });
    halfDaysFocus.addListener(() {
      if (halfDaysFocus.hasFocus) _ensureVisible(halfDaysKey);
    });
    amountFocus.addListener(() {
      if (amountFocus.hasFocus) _ensureVisible(amountKey);
    });
  }

  /// Widget'ı görünür hale getirir
  Future<void> _ensureVisible(GlobalKey key) async {
    await Future.delayed(const Duration(milliseconds: 60));
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: 0.2,
    );
  }

  /// Tüm focus node'ları dispose eder
  void dispose() {
    dailyRateFocus.dispose();
    fullDaysFocus.dispose();
    halfDaysFocus.dispose();
    amountFocus.dispose();
  }
}
