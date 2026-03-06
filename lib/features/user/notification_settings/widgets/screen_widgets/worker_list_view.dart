import 'package:flutter/material.dart';
import '../../../../../models/worker.dart';
import '../../../../../screens/constants/colors.dart';

class WorkerListView extends StatelessWidget {
  final List<Worker> workers;
  final bool isLoading;
  final Function(Worker worker) onWorkerTap;

  const WorkerListView({
    super.key,
    required this.workers,
    required this.isLoading,
    required this.onWorkerTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 24.0 : 16.0;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workers.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.person_search,
                size: 40,
                color: primaryIndigo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Çalışan bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(padding),
      itemCount: workers.length,
      // ⚡ PHASE 4: ListView optimizasyonları
      addAutomaticKeepAlives: false, // Memory optimizasyonu
      addRepaintBoundaries: true, // Repaint optimizasyonu
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final worker = workers[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => onWorkerTap(worker),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryIndigo,
                          primaryIndigo.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        worker.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (worker.title != null &&
                            worker.title!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            worker.title!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add_alert,
                      color: primaryIndigo,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
