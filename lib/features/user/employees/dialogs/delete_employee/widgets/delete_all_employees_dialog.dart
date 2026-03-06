import 'package:flutter/material.dart';

/// Tüm çalışanları silme dialog'u
class DeleteAllEmployeesDialog extends StatelessWidget {
  final Future<void> Function() onDeleteAll;
  final VoidCallback onComplete;

  const DeleteAllEmployeesDialog({
    super.key,
    required this.onDeleteAll,
    required this.onComplete,
  });

  /// Dialog'u göster
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onDeleteAll,
    required VoidCallback onComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // Navigation bar'dan korunur
      backgroundColor: Colors.transparent,
      builder: (context) => DeleteAllEmployeesDialog(
        onDeleteAll: onDeleteAll,
        onComplete: onComplete,
      ),
    );
  }

  Future<void> _handleDeleteAll(BuildContext context) async {
    // İkinci onay dialog'u göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Son Onay'),
          ],
        ),
        content: Text(
          'Bu işlem GERİ ALINAMAZ!\n\nTüm çalışanlar ve tüm devam/ödeme kayıtları kalıcı olarak silinecek.\n\nDevam etmek istediğinizden emin misiniz?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    Navigator.pop(context);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('DeleteAllEmployeesDialog: Tüm çalışanlar siliniyor');

      await onDeleteAll();
      onComplete();

      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Tüm çalışanlar silindi.', style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: Colors.green,
        ),
      );

      debugPrint('DeleteAllEmployeesDialog: Tüm çalışanlar silindi');
    } catch (e) {
      debugPrint('DeleteAllEmployeesDialog: Hata: $e');

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('İşlem sırasında bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_sweep, size: 40, color: Colors.red),
                ),
                SizedBox(height: 24),
                // Title
                Text(
                  'Tüm Çalışanları Sil',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                // Description
                Text(
                  'Tüm çalışanları ve ilişkili devam/ödeme kayıtlarını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                // Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _handleDeleteAll(context),
                      icon: Icon(Icons.delete_forever, size: 18),
                      label: Text(
                        'Tüm Çalışanları Sil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('İptal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
