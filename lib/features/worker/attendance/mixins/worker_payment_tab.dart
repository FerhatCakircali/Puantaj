import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'worker_attendance_helpers.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF4338CA);

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (paymentHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: w * 0.15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: h * 0.02),
            Text(
              'Ödeme kaydı bulunamadı',
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.015, w * 0.06, h * 0.1),
        itemCount: paymentHistory.length,
        itemExtent: h * 0.21,
        itemBuilder: (context, index) {
          final payment = paymentHistory[index];

          final paymentDate = _parseDate(payment['payment_date']);
          final displayTime = _getDisplayTime(payment);
          final amount = (payment['amount'] as num).toDouble();
          final notes = _getEffectiveNotes(payment);
          final advanceDeducted =
              (payment['advance_deducted'] as num?)?.toDouble() ?? 0.0;
          final advanceCount = payment['advance_count'] as int? ?? 0;

          final daysInfo = WorkerAttendanceHelpers.extractDaysInfo(notes);
          final fullDays = WorkerAttendanceHelpers.extractFullDays(notes);
          final halfDays = WorkerAttendanceHelpers.extractHalfDays(notes);

          return Container(
            margin: EdgeInsets.only(bottom: h * 0.015),
            padding: EdgeInsets.all(w * 0.045),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      padding: EdgeInsets.all(w * 0.03),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  primaryColor.withValues(alpha: 0.3),
                                  primaryColor.withValues(alpha: 0.2),
                                ]
                              : [
                                  primaryColor.withValues(alpha: 0.15),
                                  primaryColor.withValues(alpha: 0.1),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: primaryColor,
                        size: w * 0.065,
                      ),
                    ),
                    SizedBox(width: w * 0.035),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'dd MMMM yyyy',
                              'tr_TR',
                            ).format(paymentDate),
                            style: TextStyle(
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE', 'tr_TR').format(paymentDate),
                            style: TextStyle(
                              fontSize: w * 0.035,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          SizedBox(height: h * 0.004),
                          Text(
                            'Saat: ${DateFormat('HH:mm', 'tr_TR').format(displayTime)}',
                            style: TextStyle(
                              fontSize: w * 0.032,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          if (daysInfo.isNotEmpty) ...[
                            SizedBox(height: h * 0.006),
                            Text(
                              daysInfo,
                              style: TextStyle(
                                fontSize: w * 0.035,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: w * 0.025),
                    // Amount
                    Text(
                      '₺${WorkerAttendanceHelpers.formatCurrencySimple(amount)}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.055,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                if (fullDays > 0 || halfDays > 0 || advanceDeducted > 0) ...[
                  SizedBox(height: h * 0.01),
                  Container(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  SizedBox(height: h * 0.006),
                  Wrap(
                    spacing: w * 0.012,
                    runSpacing: h * 0.004,
                    children: [
                      if (fullDays > 0)
                        _buildDayBadge(
                          w: w,
                          h: h,
                          isDark: isDark,
                          icon: Icons.check_circle,
                          color: Colors.green,
                          text: '$fullDays Tam Gün',
                        ),
                      if (halfDays > 0)
                        _buildDayBadge(
                          w: w,
                          h: h,
                          isDark: isDark,
                          icon: Icons.schedule,
                          color: Colors.orange,
                          text: '$halfDays Yarım Gün',
                        ),
                      if (advanceDeducted > 0)
                        _buildDayBadge(
                          w: w,
                          h: h,
                          isDark: isDark,
                          icon: Icons.remove_circle_outline,
                          color: Colors.red,
                          text:
                              '-₺${WorkerAttendanceHelpers.formatCurrencySimple(advanceDeducted)} Avans',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayBadge({
    required double w,
    required double h,
    required bool isDark,
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: h * 0.003),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: w * 0.028),
          SizedBox(width: w * 0.008),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: w * 0.025,
            ),
          ),
        ],
      ),
    );
  }

  DateTime _parseDate(dynamic dateRaw) {
    if (dateRaw is String) {
      return DateTime.parse(dateRaw);
    } else if (dateRaw is DateTime) {
      return dateRaw;
    }
    debugPrint('⚠️ Geçersiz tarih formatı: $dateRaw');
    return DateTime.now();
  }

  DateTime _getDisplayTime(Map<String, dynamic> payment) {
    final updatedAtRaw = payment['updated_at'];
    final createdAtRaw = payment['created_at'];

    if (updatedAtRaw != null) {
      if (updatedAtRaw is String) {
        return DateTime.parse(updatedAtRaw).toLocal();
      } else if (updatedAtRaw is DateTime) {
        return updatedAtRaw.toLocal();
      }
    }

    if (createdAtRaw != null) {
      if (createdAtRaw is String) {
        return DateTime.parse(createdAtRaw).toLocal();
      } else if (createdAtRaw is DateTime) {
        return createdAtRaw.toLocal();
      }
    }

    return _parseDate(payment['payment_date']);
  }

  String _getEffectiveNotes(Map<String, dynamic> payment) {
    final notes = payment['notes'] as String?;

    if (notes != null && notes != 'null' && notes.isNotEmpty) {
      return notes;
    }

    final fullDaysFromDb = payment['full_days'] as int? ?? 0;
    final halfDaysFromDb = payment['half_days'] as int? ?? 0;

    if (fullDaysFromDb > 0 || halfDaysFromDb > 0) {
      final totalDays = fullDaysFromDb + halfDaysFromDb;
      final result =
          '$totalDays gün için ödeme\n'
          '${fullDaysFromDb > 0 ? '$fullDaysFromDb Tam Gün' : ''}'
          '${fullDaysFromDb > 0 && halfDaysFromDb > 0 ? ' ' : ''}'
          '${halfDaysFromDb > 0 ? '$halfDaysFromDb Yarım Gün' : ''}';

      debugPrint('📝 Notes oluşturuldu: "$result"');
      return result;
    }

    return '';
  }
}
