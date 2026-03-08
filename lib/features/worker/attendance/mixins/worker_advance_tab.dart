import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'worker_attendance_helpers.dart';

/// Avans geçmişi tab widget'ı
class WorkerAdvanceTab extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> advanceHistory;
  final VoidCallback onRefresh;

  const WorkerAdvanceTab({
    super.key,
    required this.isLoading,
    required this.advanceHistory,
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

    if (advanceHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: w * 0.15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: h * 0.02),
            Text(
              'Avans kaydı bulunamadı',
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
        itemCount: advanceHistory.length,
        itemBuilder: (context, index) {
          final advance = advanceHistory[index];

          final advanceDate = _parseDate(advance['advance_date']);
          final createdAt = _parseDate(advance['created_at']);
          final updatedAt = advance['updated_at'] != null
              ? _parseDate(advance['updated_at'])
              : null;
          final amount = (advance['amount'] as num).toDouble();
          final description = advance['description'] as String? ?? '';
          final isDeducted = advance['is_deducted'] as bool? ?? false;

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
                        Icons.payments_outlined,
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
                            ).format(advanceDate),
                            style: TextStyle(
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE', 'tr_TR').format(advanceDate),
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
                            'Saat: ${DateFormat('HH:mm', 'tr_TR').format(createdAt)}',
                            style: TextStyle(
                              fontSize: w * 0.032,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          if (updatedAt != null &&
                              updatedAt.difference(createdAt).inMinutes >
                                  1) ...[
                            SizedBox(height: h * 0.004),
                            Text(
                              'Güncelleme: ${DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(updatedAt)}',
                              style: TextStyle(
                                fontSize: w * 0.03,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
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
                if (description.isNotEmpty || isDeducted) ...[
                  SizedBox(height: h * 0.01),
                  Container(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  SizedBox(height: h * 0.008),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: w * 0.033,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  if (isDeducted) ...[
                    if (description.isNotEmpty) SizedBox(height: h * 0.006),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.025,
                        vertical: h * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: w * 0.035,
                          ),
                          SizedBox(width: w * 0.01),
                          Text(
                            'Ödemeden düşüldü',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: w * 0.03,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (description.isEmpty) ...[
                    // Açıklama yoksa ve düşülmediyse "Bekliyor" göster
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.025,
                        vertical: h * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.orange,
                            size: w * 0.035,
                          ),
                          SizedBox(width: w * 0.01),
                          Text(
                            'Bekliyor',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: w * 0.03,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
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
}
