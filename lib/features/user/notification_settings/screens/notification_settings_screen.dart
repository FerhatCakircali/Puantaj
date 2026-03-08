import 'package:flutter/material.dart';
import '../../../../models/worker.dart';
import '../mixins/notification_state_mixin.dart';
import '../mixins/notification_data_mixin.dart';
import '../mixins/notification_permission_mixin.dart';
import '../../notification_settings/widgets/screen_widgets/index.dart';

/// Bildirim ayarları ekranı
/// Sadeleştirilmiş versiyon - Tüm business logic Mixin'lerde
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with
        SingleTickerProviderStateMixin,
        NotificationStateMixin<NotificationSettingsScreen>,
        NotificationDataMixin<NotificationSettingsScreen>,
        NotificationPermissionMixin<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    initializeNotificationState();
    checkNotificationPermission();
    loadSettings();
    loadWorkers();
    loadReminders();
    checkSavedTabIndex();
  }

  @override
  void dispose() {
    disposeNotificationState();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadReminders();
  }

  Future<void> _showEmployeeReminderDialog(Worker worker) async {
    await showDialog(
      context: context,
      builder: (context) => EmployeeReminderDialog(
        worker: worker,
        onReminderAdded: loadReminders,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Modern Tab Bar
            Container(
              margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: tabController,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.notifications_active, size: 18),
                    text: 'Yevmiye',
                  ),
                  Tab(icon: Icon(Icons.person_add, size: 18), text: 'Çalışan'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  // Tab 1: Yevmiye Hatırlatıcısı
                  GlobalToggleSection(
                    isLoading: isLoading,
                    isEnabled: isEnabled,
                    autoApproveTrusted: autoApproveTrusted,
                    selectedTime: selectedTime,
                    settings: settings,
                    hasNotificationPermission: hasNotificationPermission,
                    onToggleChanged: handleToggleChanged,
                    onAutoApproveChanged: handleAutoApproveChanged,
                    onTimeSelect: selectTime,
                    onSaveSettings: saveSettings,
                    onRequestPermissions: requestPermissions,
                  ),

                  // Tab 2: Çalışan Hatırlatıcıları
                  Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Çalışan ara...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: filterWorkers,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab bar for workers and reminders
                      Expanded(
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TabBar(
                                  labelColor: colorScheme.onPrimary,
                                  unselectedLabelColor:
                                      colorScheme.onSurfaceVariant,
                                  indicator: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  tabs: const [
                                    Tab(text: 'Çalışanlar'),
                                    Tab(text: 'Hatırlatıcılar'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    // Workers list
                                    WorkerListView(
                                      workers: filteredWorkers,
                                      isLoading: isLoadingWorkers,
                                      onWorkerTap: _showEmployeeReminderDialog,
                                    ),

                                    // Reminders list
                                    ReminderListView(
                                      reminders: filteredReminders,
                                      isLoading: isLoadingReminders,
                                      onRefresh: loadReminders,
                                      onDelete: deleteReminder,
                                      onAddNew: () {
                                        // Boş fonksiyon - Add new butonu WorkerListView'da
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
