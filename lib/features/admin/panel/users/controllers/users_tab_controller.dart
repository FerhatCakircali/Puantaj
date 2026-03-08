import 'package:flutter/material.dart';
import '../../../../../services/auth_service.dart';
import '../utils/turkish_text_comparator.dart';

/// Kullanıcı listesi kontrolcüsü
///
/// Kullanıcı yükleme, filtreleme, sıralama ve sayfalama işlemlerini yönetir.
class UsersTabController extends ChangeNotifier {
  final AuthService _authService;

  UsersTabController(this._authService);

  static const int pageSize = 20;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _currentPage = 0;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> get filteredUsers => _filteredUsers;

  String _currentFilter = 'all';
  String get currentFilter => _currentFilter;

  String _searchQuery = '';

  /// Kullanıcıları yükle
  Future<void> loadUsers() async {
    _isLoading = true;
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();

    try {
      final users = await _authService.getAllUsers();
      _allUsers = users;
      _filteredUsers = users.take(pageSize).toList();
      _hasMore = users.length > pageSize;
      _sortUsers(_filteredUsers);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Daha fazla kullanıcı yükle (sayfalama)
  Future<void> loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _currentPage++;
    final startIndex = _currentPage * pageSize;
    final endIndex = startIndex + pageSize;

    if (startIndex < _allUsers.length) {
      final moreUsers = _allUsers.skip(startIndex).take(pageSize).toList();
      _filteredUsers.addAll(moreUsers);
      _hasMore = endIndex < _allUsers.length;
    } else {
      _hasMore = false;
    }

    _isLoadingMore = false;
    notifyListeners();
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

      final filteredIndex = _filteredUsers.indexWhere((u) => u['id'] == userId);
      if (filteredIndex != -1) {
        _filteredUsers[filteredIndex] = response;
        _sortUsers(_filteredUsers);
      }

      notifyListeners();
    } catch (e) {
      await loadUsers();
    }
  }

  /// Filtreyi değiştir
  void setFilter(String filter) {
    _currentFilter = filter;
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

    switch (_currentFilter) {
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
      _filteredUsers = baseList;
    } else {
      _filteredUsers = baseList.where((user) {
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
    }

    _sortUsers(_filteredUsers);
    notifyListeners();
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
