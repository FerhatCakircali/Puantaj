import 'package:flutter/material.dart';

/// Rapor yükleme göstergesi widget'ı
///
/// PDF oluşturma ilerlemesini gösterir.
class ReportLoadingIndicator extends StatelessWidget {
  final ValueNotifier<double> progressNotifier;

  const ReportLoadingIndicator({super.key, required this.progressNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: progressNotifier,
      builder: (context, progress, child) {
        if (progress > 0 && progress < 1) {
          return Column(
            children: [
              _buildProgressBar(context, progress),
              const SizedBox(height: 8),
              _buildProgressText(context, progress),
              const SizedBox(height: 16),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey.shade200,
      valueColor: AlwaysStoppedAnimation<Color>(
        Theme.of(context).colorScheme.primary,
      ),
      minHeight: 6,
      borderRadius: BorderRadius.circular(3),
    );
  }

  Widget _buildProgressText(BuildContext context, double progress) {
    return Text(
      'PDF oluşturuluyor... ${(progress * 100).toInt()}%',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
