import 'package:flutter/material.dart';

/// Dialog header widget'ı
///
/// Icon, başlık, açıklama ve kapat butonu içerir.
class DialogHeader extends StatelessWidget {
  final double screenWidth;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onClose;

  const DialogHeader({
    super.key,
    required this.screenWidth,
    required this.theme,
    required this.colorScheme,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          screenWidth * 0.06,
          screenWidth * 0.05,
          screenWidth * 0.06,
          screenWidth * 0.04,
        ),
        child: Row(
          children: [
            _buildIcon(),
            SizedBox(width: screenWidth * 0.04),
            Expanded(child: _buildTitleSection()),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: screenWidth * 0.12,
      height: screenWidth * 0.12,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: colorScheme.onPrimary, size: screenWidth * 0.06),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      onPressed: onClose,
      icon: const Icon(Icons.close),
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
