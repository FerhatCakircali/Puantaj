import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../widgets/shimmer_loading.dart';
import 'controllers/users_tab_controller.dart';
import 'widgets/users_search_bar.dart';
import 'widgets/users_filter_chips.dart';
import 'widgets/users_list_view.dart';
import 'widgets/users_empty_state.dart';

/// Kullanıcı yönetimi sekmesi
///
/// Admin panelinde kullanıcıları listeleme, arama, filtreleme ve düzenleme işlemlerini sağlar.
class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  late final UsersTabController _controller;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = UsersTabController(AuthService());
    _controller.loadUsers();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.removeListener(_onSearchChanged);
    _scrollController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMoreUsers();
    }
  }

  void _onSearchChanged() {
    _controller.updateSearchQuery(_searchController.text);
  }

  void _onClearSearch() {
    _searchController.clear();
    _controller.updateSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const UserListShimmer();
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  UsersSearchBar(
                    controller: _searchController,
                    onClear: _onClearSearch,
                  ),
                  const SizedBox(height: 12),
                  UsersFilterChips(
                    currentFilter: _controller.currentFilter,
                    onFilterChanged: _controller.setFilter,
                    userCount: _controller.filteredUsers.length,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _controller.filteredUsers.isEmpty
                  ? UsersEmptyState(
                      hasSearchQuery: _searchController.text.isNotEmpty,
                    )
                  : UsersListView(
                      users: _controller.filteredUsers,
                      authService: AuthService(),
                      scrollController: _scrollController,
                      hasMore: _controller.hasMore,
                      isLoadingMore: _controller.isLoadingMore,
                      onUserRefresh: _controller.refreshSingleUser,
                    ),
            ),
          ],
        );
      },
    );
  }
}
