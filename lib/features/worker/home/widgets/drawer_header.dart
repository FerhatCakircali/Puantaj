import 'package:flutter/material.dart';

/// Modern Worker Drawer başlık widget'ı - Minimal tasarım - Responsive
class WorkerHomeScreenDrawerHeader extends StatelessWidget {
  final String? workerName;
  final String? workerUsername;

  const WorkerHomeScreenDrawerHeader({
    super.key,
    required this.workerName,
    required this.workerUsername,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // İsmin baş harfini al
    final initial = (workerName != null && workerName!.isNotEmpty)
        ? workerName![0].toUpperCase()
        : 'Ç';

    return Container(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.04,
        screenHeight * 0.05,
        screenWidth * 0.04,
        screenHeight * 0.025,
      ),
      child: Column(
        children: [
          // Avatar with initial
          Container(
            width: screenWidth * 0.2,
            height: screenWidth * 0.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: screenWidth * 0.03,
                  offset: Offset(0, screenHeight * 0.005),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: screenWidth * 0.09,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.017),
          // Worker name
          Text(
            workerName ?? 'Çalışan',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              fontSize: screenWidth * 0.045,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: screenHeight * 0.005),
          // Role
          Text(
            'Çalışan',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: screenWidth * 0.035,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
