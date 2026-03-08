import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/employee_reminder.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/app_globals.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/user_data_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../home/mixins/home_drawer.dart';
import '../widgets/index.dart';
import '../loaders/reminder_loader.dart';
import '../handlers/reminder_delete_handler.dart';
import '../handlers/navigation_handler.dart';

class EmployeeReminderDetailScreen extends ConsumerStatefulWidget {
  final int? reminderId;

  const EmployeeReminderDetailScreen({super.key, this.reminderId});

  @override
  ConsumerState<EmployeeReminderDetailScreen> createState() =>
      _EmployeeReminderDetailScreenState();
}

class _EmployeeReminderDetailScreenState
    extends ConsumerState<EmployeeReminderDetailScreen> {
  final ReminderLoader _reminderLoader = ReminderLoader();
  final ReminderDeleteHandler _deleteHandler = ReminderDeleteHandler();

  bool _isLoading = true;
  bool _isDeleting = false;
  EmployeeReminder? _reminder;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reminder = await _reminderLoader.load(widget.reminderId);

      if (!mounted) return;

      if (reminder == null) {
        _showSnackBar('Hatırlatıcı bulunamadı');
        return;
      }

      setState(() {
        _reminder = reminder;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Hatırlatıcı yüklenirken bir hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userDataProvider);
    final firstName = currentUser?['first_name'] as String? ?? '';
    final lastName = currentUser?['last_name'] as String? ?? '';
    final isAdmin = currentUser?['is_admin'] == true;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: globalScaffoldKey,
      appBar: AppBar(title: const Text('Çalışan Hatırlatıcısı')),
      drawer: HomeDrawer(
        firstName: firstName,
        lastName: lastName,
        isAdmin: isAdmin,
        selectedIndex: null,
        onItemTap: (index) async {
          await NavigationHandler.navigateToTab(context, index);
        },
        onThemeToggle: () async {
          final currentMode = ref.read(themeStateProvider);
          final newMode = currentMode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark;

          // Riverpod provider ile tema değiştir (otomatik kaydeder)
          ref.read(themeStateProvider.notifier).setTheme(newMode);
        },
        onLogout: () {
          Navigator.pop(context); // Drawer'ı kapat

          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Çıkış Yap'),
              content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hayır'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext); // Dialog'u kapat

                    try {
                      final authService = AuthService();
                      await authService.signOut();

                      if (!mounted || !context.mounted) return;

                      final container = ProviderScope.containerOf(context);
                      container.read(authStateProvider.notifier).logout();
                      NavigationHandler.navigateToLogin(context);
                    } catch (e) {
                      if (!mounted) return;
                      NavigationHandler.navigateToLogin(context);
                    }
                  },
                  child: const Text('Evet'),
                ),
              ],
            ),
          );
        },
        isDarkMode: isDarkMode,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminder == null
          ? const Center(child: Text('Hatırlatıcı bulunamadı'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReminderHeader(reminder: _reminder!),
                          ReminderMessageCard(reminder: _reminder!),
                        ],
                      ),
                    ),
                  ),
                  ReminderActionButtons(
                    isDeleting: _isDeleting,
                    onConfirm: _showDeleteConfirmationDialog,
                  ),
                ],
              ),
            ),
    );
  }

  void _showDeleteConfirmationDialog() {
    DeleteConfirmationDialog.show(context, onConfirm: _deleteReminder);
  }

  // Hatırlatıcıyı sil
  Future<void> _deleteReminder() async {
    if (_reminder?.id == null) {
      if (mounted) {
        _showSnackBar('Hatırlatıcı bulunamadı');
      }
      return;
    }

    if (_isDeleting || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    final reminderId = _reminder!.id!;

    try {
      final success = await _deleteHandler.delete(reminderId);

      if (!mounted) return;

      if (success) {
        // SnackBar göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hatırlatıcı başarıyla silindi'),
            duration: Duration(seconds: 2),
          ),
        );

        // Geri dön
        await NavigationHandler.navigateBack(context);
      } else {
        if (mounted) {
          _showSnackBar('Hatırlatıcı silinirken bir hata oluştu');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Hatırlatıcı silinirken bir hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
