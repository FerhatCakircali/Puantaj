import 'package:flutter/material.dart';

class UserAccountsScreen extends StatefulWidget {
  const UserAccountsScreen({super.key});

  @override
  State<UserAccountsScreen> createState() => _UserAccountsScreenState();
}

class _UserAccountsScreenState extends State<UserAccountsScreen> {
  final bool _isLoading = true;
  final bool _isProcessing = false; // İşlem yapılıyor mu takip eder
  final List<Map<String, dynamic>> _savedAccounts = [];
  final Map<String, dynamic>? _currentUser = null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Accounts')),
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : ListView.builder(
                  itemCount: _savedAccounts.length,
                  itemBuilder: (context, index) {
                    final account = _savedAccounts[index];
                    return ListTile(
                      title: Text(account['username'] ?? 'Unknown'),
                    );
                  },
                ),
      ),
    );
  }
}
