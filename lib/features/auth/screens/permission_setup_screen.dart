import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/notification/mixins/notification_permission_mixin.dart';

class PermissionSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionSetupScreen({super.key, required this.onComplete});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen>
    with NotificationPermissionMixin {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                'Bildirim İzinleri',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Puantaj uygulamasının düzgün çalışması için aşağıdaki izinlere ihtiyaç var:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildPermissionItem(
                Icons.notifications,
                'Bildirimler',
                'Yevmiye hatırlatıcıları ve bildirimler için',
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                Icons.alarm,
                'Zamanlanmış Alarmlar',
                'Tam zamanında hatırlatıcılar için',
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                Icons.battery_charging_full,
                'Pil Optimizasyonu',
                'Arka planda çalışabilmek için',
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                Icons.power_settings_new,
                'Otomatik Başlatma',
                'Cihaz yeniden başladığında çalışmak için',
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isLoading ? null : _handlePermissions,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'İzinleri Ver',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _skipPermissions,
                child: const Text('Daha Sonra'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tüm izinleri ve ayarları iste
      await requestAllPermissionsAndSettings(context);

      // İzin kurulumunun tamamlandığını kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permission_setup_completed', true);

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      debugPrint('İzin kurulumu hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İzinler ayarlanırken bir hata oluştu')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _skipPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permission_setup_completed', true);
    widget.onComplete();
  }
}
