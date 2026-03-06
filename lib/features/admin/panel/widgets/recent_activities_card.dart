import 'package:flutter/material.dart';
import '../../../../models/activity_log.dart';
import '../../../../utils/cached_future_builder.dart';
import '../services/activity_log_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class RecentActivitiesCard extends StatelessWidget {
  const RecentActivitiesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final activityLogService = ActivityLogService();

    // Türkçe timeago mesajları
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Son Aktiviteler',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CachedFutureBuilder<List<ActivityLog>>(
              future: () => activityLogService.getRecentActivities(limit: 5),
              cacheDuration: const Duration(minutes: 2),
              cacheKey: 'recent_activities',
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Aktiviteler yüklenemedi',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  );
                }

                final activities = snapshot.data ?? [];

                if (activities.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Henüz aktivite yok',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityItem(context, activity);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityLog activity) {
    IconData icon;
    Color iconColor;

    switch (activity.actionType) {
      case 'user_created':
        icon = Icons.person_add;
        iconColor = Colors.green;
        break;
      case 'user_updated':
        icon = Icons.edit;
        iconColor = Colors.blue;
        break;
      case 'user_deleted':
        icon = Icons.person_remove;
        iconColor = Colors.red;
        break;
      case 'user_blocked':
        icon = Icons.block;
        iconColor = Colors.red;
        break;
      case 'user_unblocked':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'admin_granted':
        icon = Icons.admin_panel_settings;
        iconColor = Colors.orange;
        break;
      case 'admin_revoked':
        icon = Icons.remove_moderator;
        iconColor = Colors.orange;
        break;
      case 'login':
        icon = Icons.login;
        iconColor = Colors.blue;
        break;
      case 'logout':
        icon = Icons.logout;
        iconColor = Colors.grey;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.grey;
    }

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(icon, size: 16, color: iconColor),
      ),
      title: Text(
        activity.actionDescription,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${activity.adminUsername} → ${activity.targetInfo}',
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Text(
        timeago.format(activity.createdAt, locale: 'tr'),
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}
