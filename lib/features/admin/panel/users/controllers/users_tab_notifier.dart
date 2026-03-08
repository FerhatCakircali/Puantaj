import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../core/di/service_locator.dart';
import '../utils/turkish_text_comparator.dart';
import '../../../../../core/providers/base_loading_state.dart';

/// Kullanıcı listesi state
class UsersTabState with LoadingStateMixin {
  @override
  final bool isLoading;

  @override
  final String? errorMessage;

  final bool isLoadingMore;
  final bool hasMore;
  final List<Map<String, dynamic>> filteredUsers;
  final String currentFilter;

  const UsersTabState({
    this.isLoading = true,
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.filteredUsers = const [],
    this.currentFilter = 'all',
  });

  UsersTabState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isLoadingMore,
    bool? hasMore,
    List<Map<String, dynamic>>? filteredUsers,
    String? currentFilter,
  }) {
    return UsersTabState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

/// Kullanıcı listesi notifier
class UsersTabNotifier extends Notifier<UsersTabState> {
  static const int pageSize = 20;

  late final AuthService _authService;
  int _currentPage = 0;
  List<Map<String, dynamic>> _allUsers = [];
  String _searchQuery = '';

  @override
  UsersTabState build() {
    _authService = getIt<AuthService>();
    return const UsersTabState();
  }

  /// Kullanıcıları yükle
  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true);
    _currentPage = 0;

    try {
      final users = await _authService.getAllUsers();
      _allUsers = users;
      final filteredUsers = users.take(pageSize).toList();
      _sortUsers(filteredUsers);

      state = state.copyWith(
        isLoading: false,
        filteredUsers: filteredUsers,
        hasMore: users.length > pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Daha fazla kullanıcı yükle (sayfalama)
  Future<void> loadMoreUsers() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    await Future.delayed(const Duration(milliseconds: 500));

    _currentPage++;
    final startIndex = _currentPage * pageSize;
    final endIndex = startIndex + pageSize;

    if (startIndex < _allUsers.length) {
      final moreUsers = _allUsers.skip(startIndex).take(pageSize).toList();
      final updatedUsers = [...state.filteredUsers, ...moreUsers];

      state = state.copyWith(
        isLoadingMore: false,
        filteredUsers: updatedUsers,
        hasMore: endIndex < _allUsers.length,
      );
    } else {
      state = state.copyWith(isLoadingMore: false, hasMore: false);
    }
  }

  /// Tek bir kullanıcıyı yenile
  Future<void> refreshSingleUser(int userId) async {
    try {
      final response = await _authService.supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return;

      final userIndex = _allUsers.indexWhere((u) => u['id'] == userId);
      if (userIndex != -1) {
        _allUsers[userIndex] = response;
      }

      final filteredIndex = state.filteredUsers.indexWhere(
        (u) => u['id'] == userId,
      );
      if (filteredIndex != -1) {
        final updatedUsers = [...state.filteredUsers];
        updatedUsers[filteredIndex] = response;
        _sortUsers(updatedUsers);

        state = state.copyWith(filteredUsers: updatedUsers);
      }
    } catch (e) {
      await loadUsers();
    }
  }

  /// Filtreyi değiştir
  void setFilter(String filter) {
    state = state.copyWith(currentFilter: filter);
    _applyFilters();
  }

  /// Arama sorgusunu güncelle
  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  /// Filtreleri uygula
  void _applyFilters() {
    List<Map<String, dynamic>> baseList;

    switch (state.currentFilter) {
      case 'active':
        baseList = _allUsers
            .where((user) => !(user['is_blocked'] as bool))
            .toList();
        break;
      case 'blocked':
        baseList = _allUsers
            .where((user) => user['is_blocked'] as bool)
            .toList();
        break;
      case 'admin':
        baseList = _allUsers.where((user) {
          final isAdmin = user['is_admin'];
          return isAdmin == 1 || isAdmin == true;
        }).toList();
        break;
      default:
        baseList = _allUsers;
    }

    if (_searchQuery.isEmpty) {
      _sortUsers(baseList);
      state = state.copyWith(filteredUsers: baseList);
    } else {
      final filtered = baseList.where((user) {
        final firstName = (user['first_name'] ?? '').toString().toLowerCase();
        final lastName = (user['last_name'] ?? '').toString().toLowerCase();
        final username = (user['username'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final jobTitle = (user['job_title'] ?? '').toString().toLowerCase();

        return firstName.contains(_searchQuery) ||
            lastName.contains(_searchQuery) ||
            username.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            jobTitle.contains(_searchQuery);
      }).toList();

      _sortUsers(filtered);
      state = state.copyWith(filteredUsers: filtered);
    }
  }

  /// Kullanıcıları sırala
  void _sortUsers(List<Map<String, dynamic>> users) {
    users.sort((a, b) {
      final aIsSystemAdmin = _authService.isSystemAdmin(a);
      final bIsSystemAdmin = _authService.isSystemAdmin(b);
      final aIsAdmin = a['is_admin'] == 1 || a['is_admin'] == true;
      final bIsAdmin = b['is_admin'] == 1 || b['is_admin'] == true;
      final aIsBlocked = a['is_blocked'] as bool;
      final bIsBlocked = b['is_blocked'] as bool;

      if (aIsSystemAdmin && !bIsSystemAdmin) return -1;
      if (!aIsSystemAdmin && bIsSystemAdmin) return 1;

      if (aIsAdmin && !bIsAdmin && !bIsSystemAdmin) return -1;
      if (!aIsAdmin && bIsAdmin && !aIsSystemAdmin) return 1;

      if (aIsAdmin == bIsAdmin) {
        if (aIsBlocked && !bIsBlocked) return -1;
        if (!aIsBlocked && bIsBlocked) return 1;
      }

      final aName = '${a['first_name'] ?? ''} ${a['last_name'] ?? ''}'.trim();
      final bName = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();

      return TurkishTextComparator.compare(aName, bName);
    });
  }
}

/// Provider
final usersTabNotifierProvider =
    NotifierProvider<UsersTabNotifier, UsersTabState>(() => UsersTabNotifier());
