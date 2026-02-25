import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/auth_service.dart';
import '../../user_detail/widgets/screen_widgets/index.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _isLoading = true);

    try {
      final users = await _authService.getAllUsers();
      final user = users.firstWhere(
        (u) => u['id'] == widget.userId,
        orElse: () => {},
      );

      if (user.isNotEmpty) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Kullanıcı bulunamadı')));
          GoRouter.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _updateUser({
    required String username,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required bool isAdmin,
  }) async {
    setState(() => _isUpdating = true);

    try {
      final error = await _authService.updateUser(
        userId: widget.userId,
        username: username,
        firstName: firstName,
        lastName: lastName,
        jobTitle: jobTitle,
        isAdmin: isAdmin,
      );

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      } else {
        await _loadUserDetails(); // Kullanıcı bilgilerini yenile
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı başarıyla güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _toggleBlockStatus() async {
    if (_user == null) return;

    final currentStatus = _user!['is_blocked'] as bool? ?? false;
    final newStatus = !currentStatus;

    setState(() => _isUpdating = true);

    try {
      final error = await _authService.updateUserBlockedStatus(
        widget.userId,
        newStatus,
      );

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      } else {
        await _loadUserDetails(); // Kullanıcı bilgilerini yenile
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus
                    ? 'Kullanıcı bloklandı'
                    : 'Kullanıcı bloku kaldırıldı',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Blok durumu güncellenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmDialog(user: _user!),
    );

    if (confirmed != true) return;

    setState(() => _isUpdating = true);

    try {
      final error = await _authService.deleteUser(widget.userId);

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
          GoRouter.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showEditDialog() {
    if (_user == null) return;

    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: _user!,
        isUpdating: _isUpdating,
        onUpdate: _updateUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Detayları'),
        actions: _user != null
            ? [
                IconButton(
                  onPressed: _isUpdating ? null : _showEditDialog,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Düzenle',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'block':
                        _toggleBlockStatus();
                        break;
                      case 'delete':
                        _deleteUser();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final isBlocked = _user!['is_blocked'] as bool? ?? false;
                    final isMainAdmin =
                        _user!['username']?.toString().toLowerCase() == 'admin';

                    return [
                      if (!isMainAdmin) // Ana admin bloklanamaz/silinemez
                        PopupMenuItem(
                          value: 'block',
                          child: ListTile(
                            leading: Icon(
                              isBlocked ? Icons.person_add : Icons.person_off,
                              color: isBlocked ? Colors.green : Colors.orange,
                            ),
                            title: Text(
                              isBlocked ? 'Bloku Kaldır' : 'Blokla',
                              style: TextStyle(
                                color: isBlocked ? Colors.green : Colors.orange,
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      if (!isMainAdmin) // Ana admin silinemez
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Sil',
                              style: TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ];
                  },
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(
              child: Text(
                'Kullanıcı bulunamadı',
                style: TextStyle(fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserHeader(user: _user!),
                  const SizedBox(height: 24),
                  UserInfoCard(user: _user!),
                  const SizedBox(height: 24),
                  UserStatusCard(user: _user!),
                  const SizedBox(height: 24),
                  UserActionButtons(
                    user: _user!,
                    isUpdating: _isUpdating,
                    onEdit: _showEditDialog,
                    onToggleBlock: _toggleBlockStatus,
                    onDelete: _deleteUser,
                  ),
                ],
              ),
            ),
    );
  }
}
