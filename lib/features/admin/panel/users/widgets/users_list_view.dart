import 'package:flutter/material.dart';
import '../../../../../services/auth_service.dart';
import '../../widgets/user_card.dart';
import '../../widgets/user_edit_dialog.dart';

/// Kullanıcı listesi görünümü
class UsersListView extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final AuthService authService;
  final ScrollController scrollController;
  final bool hasMore;
  final bool isLoadingMore;
  final Function(int) onUserRefresh;

  const UsersListView({
    super.key,
    required this.users,
    required this.authService,
    required this.scrollController,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onUserRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: users.length + (hasMore || isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == users.length) {
          return _buildLoadingIndicator(context);
        }

        final user = users[index];
        return UserCard(
          user: user,
          authService: authService,
          onTap: () => _handleUserEdit(context, user),
          onEdit: () => _handleUserEdit(context, user),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Tüm kullanıcılar yüklendi',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _handleUserEdit(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    final result = await showUserEditDialog(
      context: context,
      user: user,
      authService: authService,
    );
    if (result == true) {
      onUserRefresh(user['id']);
    }
  }
}
