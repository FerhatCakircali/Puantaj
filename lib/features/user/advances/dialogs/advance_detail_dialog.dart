import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/advance.dart';
import '../controllers/advance_controller.dart';
import 'edit_advance_dialog.dart';

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

  Future<void> _deleteAdvance(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avansı Sil'),
        content: const Text('Bu avansı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final controller = AdvanceController();
      await controller.deleteAdvance(advance.id!);

      if (!context.mounted) return;

      Navigator.pop(context);
      onAdvanceUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Avans silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
      );
    }
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
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final primaryColor = const Color(0xFF4338CA);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(w * 0.06),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve kapat butonu
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(w * 0.03),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: w * 0.06,
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Text(
                    'Avans Detayı',
                    style: TextStyle(
                      fontSize: w * 0.05,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: w * 0.06),

            // Çalışan adı
            _buildInfoRow(
              context,
              icon: Icons.person,
              label: 'Çalışan',
              value: workerName,
              w: w,
            ),
            SizedBox(height: w * 0.04),

            // Tutar
            _buildInfoRow(
              context,
              icon: Icons.currency_lira,
              label: 'Tutar',
              value:
                  '₺${advance.amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              w: w,
              valueColor: primaryColor,
              valueBold: true,
            ),
            SizedBox(height: w * 0.04),

            // Tarih
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              label: 'Tarih',
              value: DateFormat(
                'dd MMMM yyyy',
                'tr_TR',
              ).format(advance.advanceDate),
              w: w,
            ),
            SizedBox(height: w * 0.04),

            // Durum
            _buildInfoRow(
              context,
              icon: advance.isDeducted ? Icons.check_circle : Icons.pending,
              label: 'Durum',
              value: advance.isDeducted ? 'Düşüldü' : 'Bekliyor',
              w: w,
              valueColor: advance.isDeducted ? Colors.green : Colors.orange,
            ),
            SizedBox(height: w * 0.04),

            // Açıklama (varsa)
            if (advance.description != null &&
                advance.description!.isNotEmpty) ...[
              _buildInfoRow(
                context,
                icon: Icons.description,
                label: 'Açıklama',
                value: advance.description!,
                w: w,
                multiline: true,
              ),
              SizedBox(height: w * 0.04),
            ],

            SizedBox(height: w * 0.02),

            // Butonlar (sadece bekleyen avanslar için)
            if (!advance.isDeducted)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteAdvance(context),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Sil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: w * 0.035),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editAdvance(context),
                      icon: const Icon(Icons.edit),
                      label: const Text('Düzenle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: w * 0.035),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // Düşülmüş avanslar için bilgilendirme
              Container(
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green,
                      size: w * 0.05,
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: Text(
                        'Bu avans ödemeden düşülmüştür. Düzenleme ve silme işlemi yapılamaz.',
                        style: TextStyle(
                          fontSize: w * 0.035,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required double w,
    Color? valueColor,
    bool valueBold = false,
    bool multiline = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: multiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: w * 0.05, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: w * 0.032,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: w * 0.04,
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
