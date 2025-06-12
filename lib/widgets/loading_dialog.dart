import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  final String message;
  final double? progress; // 0.0 - 1.0
  final Duration? eta;
  final VoidCallback? onCancel;
  final VoidCallback? onContinue;
  const LoadingDialog({
    Key? key,
    required this.message,
    this.progress,
    this.eta,
    this.onCancel,
    this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress != null)
              Column(
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 12),
                  Text(
                    'Tahmini kalan süre: ${eta != null ? eta!.inSeconds : '-'} sn',
                  ),
                ],
              )
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onContinue != null)
                  ElevatedButton(
                    onPressed: onContinue,
                    child: const Text('Devam'),
                  ),
                if (onContinue != null && onCancel != null)
                  const SizedBox(width: 16),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel),
                    label: const Text('İptal'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
