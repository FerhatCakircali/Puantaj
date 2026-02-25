import 'package:flutter/material.dart';

import '../mixins/index.dart';

/// Çalışan hatırlatıcıları ekranı - YENİ TASARIM
class WorkerRemindersScreen extends StatefulWidget {
  const WorkerRemindersScreen({super.key});

  @override
  State<WorkerRemindersScreen> createState() => _WorkerRemindersScreenState();
}

class _WorkerRemindersScreenState extends State<WorkerRemindersScreen>
    with WorkerRemindersLogicMixin {
  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          screenWidth * 0.04,
          horizontalPadding,
          screenWidth * 0.2,
        ),
        children: [
          WorkerRemindersTodayStatusCard(
            todayStatus: todayStatus,
            onSubmitAttendance: (status) => submitAttendance(status),
          ),
          SizedBox(height: screenWidth * 0.04),
          WorkerRemindersReminderCard(
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            onReminderToggle: (value) {
              setState(() => reminderEnabled = value);
            },
            onSelectTime: selectTime,
          ),
          SizedBox(height: screenWidth * 0.04),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: screenWidth * 0.03,
            offset: Offset(0, screenWidth * 0.01),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: saveSettings,
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          elevation: 0,
        ),
        icon: Icon(Icons.save, size: screenWidth * 0.05),
        label: Text(
          'Kaydet',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
