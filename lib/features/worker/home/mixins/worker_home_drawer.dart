import 'package:flutter/material.dart';
import '../widgets/index.dart';

/// Worker home drawer widget'ı - Yeni tasarım ile uyumlu
/// Bu dosya geriye dönük uyumluluk için korunmuştur
/// Artık ../widgets/ klasöründeki modüler widget'ları kullanır
class WorkerHomeDrawer extends StatelessWidget {
  final String? workerName;
  final String? workerUsername;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onLogout;
  final VoidCallback onThemeToggle;
  final GlobalKey themeIconKey;

  const WorkerHomeDrawer({
    super.key,
    required this.workerName,
    required this.workerUsername,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onLogout,
    required this.onThemeToggle,
    required this.themeIconKey,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          WorkerHomeScreenDrawerHeader(
            workerName: workerName,
            workerUsername: workerUsername,
          ),
          WorkerHomeScreenDrawerContent(
            selectedIndex: selectedIndex,
            onItemTap: onItemTapped,
            onThemeToggle: onThemeToggle,
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }
}
