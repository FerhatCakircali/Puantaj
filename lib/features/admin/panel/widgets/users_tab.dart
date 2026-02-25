import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../widgets/shimmer_loading.dart';
import 'user_card.dart';
import 'user_filter_chip.dart';
import 'user_edit_dialog.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final _authService = AuthService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredUsers = [];
  String _currentFilter = 'all';

  // Sayfalama için
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreUsers();
      }
    }
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final users = await _authService.getAllUsers();
      if (!mounted) return;

      setState(() {
        _users = users;
        _filteredUsers = users.take(_pageSize).toList();
        _hasMore = users.length > _pageSize;
        _sortUsers(_filteredUsers);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcılar yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _currentPage++;
      final startIndex = _currentPage * _pageSize;
      final endIndex = startIndex + _pageSize;

      if (startIndex < _users.length) {
        final moreUsers = _users.skip(startIndex).take(_pageSize).toList();
        _filteredUsers.addAll(moreUsers);
        _hasMore = endIndex < _users.length;
      } else {
        _hasMore = false;
      }

      _isLoadingMore = false;
    });
  }

  // Tek bir kullanıcıyı yenile (performans optimizasyonu)
  Future<void> _refreshSingleUser(int userId) async {
    try {
      // Güncellenmiş kullanıcı verisini al
      final response = await _authService.supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null || !mounted) return;

      setState(() {
        // Ana listede güncelle
        final userIndex = _users.indexWhere((u) => u['id'] == userId);
        if (userIndex != -1) {
          _users[userIndex] = response;
        }

        // Filtrelenmiş listede güncelle
        final filteredIndex = _filteredUsers.indexWhere(
          (u) => u['id'] == userId,
        );
        if (filteredIndex != -1) {
          _filteredUsers[filteredIndex] = response;
          _sortUsers(_filteredUsers);
        }
      });
    } catch (e) {
      debugPrint('Kullanıcı yenileme hatası: $e');
      // Hata durumunda tüm listeyi yenile
      _loadUsers();
    }
  }

  // Türkçe karakterlere duyarlı karşılaştırma fonksiyonu
  int _turkishCompare(String a, String b) {
    const turkishOrder = {
      'a': 1,
      'A': 1,
      'b': 2,
      'B': 2,
      'c': 3,
      'C': 3,
      'ç': 4,
      'Ç': 4,
      'd': 5,
      'D': 5,
      'e': 6,
      'E': 6,
      'f': 7,
      'F': 7,
      'g': 8,
      'G': 8,
      'ğ': 9,
      'Ğ': 9,
      'h': 10,
      'H': 10,
      'ı': 11,
      'I': 11,
      'i': 12,
      'İ': 12,
      'j': 13,
      'J': 13,
      'k': 14,
      'K': 14,
      'l': 15,
      'L': 15,
      'm': 16,
      'M': 16,
      'n': 17,
      'N': 17,
      'o': 18,
      'O': 18,
      'ö': 19,
      'Ö': 19,
      'p': 20,
      'P': 20,
      'r': 21,
      'R': 21,
      's': 22,
      'S': 22,
      'ş': 23,
      'Ş': 23,
      't': 24,
      'T': 24,
      'u': 25,
      'U': 25,
      'ü': 26,
      'Ü': 26,
      'v': 27,
      'V': 27,
      'y': 28,
      'Y': 28,
      'z': 29,
      'Z': 29,
    };

    final aLower = a.toLowerCase();
    final bLower = b.toLowerCase();

    for (int i = 0; i < aLower.length && i < bLower.length; i++) {
      final aOrder = turkishOrder[aLower[i]] ?? 999;
      final bOrder = turkishOrder[bLower[i]] ?? 999;

      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
    }

    return aLower.length.compareTo(bLower.length);
  }

  // Kullanıcıları özel sıralama ile sırala
  void _sortUsers(List<Map<String, dynamic>> users) {
    users.sort((a, b) {
      final aIsSystemAdmin = _authService.isSystemAdmin(a);
      final bIsSystemAdmin = _authService.isSystemAdmin(b);
      // is_admin hem int (1/0) hem de bool olabilir
      final aIsAdmin = a['is_admin'] == 1 || a['is_admin'] == true;
      final bIsAdmin = b['is_admin'] == 1 || b['is_admin'] == true;
      final aIsBlocked = a['is_blocked'] as bool;
      final bIsBlocked = b['is_blocked'] as bool;

      // 1. System Admin en üstte
      if (aIsSystemAdmin && !bIsSystemAdmin) return -1;
      if (!aIsSystemAdmin && bIsSystemAdmin) return 1;

      // 2. Adminler system admin'den sonra
      if (aIsAdmin && !bIsAdmin && !bIsSystemAdmin) return -1;
      if (!aIsAdmin && bIsAdmin && !aIsSystemAdmin) return 1;

      // 3. Aynı grupta ise (admin veya user), bloklu olanlar üstte
      if (aIsAdmin == bIsAdmin) {
        if (aIsBlocked && !bIsBlocked) return -1;
        if (!aIsBlocked && bIsBlocked) return 1;
      }

      // 4. Aynı durumdaysa (aynı yetki ve blok durumu), Türkçe alfabetik sırala
      final aName = '${a['first_name'] ?? ''} ${a['last_name'] ?? ''}'.trim();
      final bName = '${b['first_name'] ?? ''} ${b['last_name'] ?? ''}'.trim();

      return _turkishCompare(aName, bName);
    });
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // İlk olarak filtreye göre kullanıcıları seç
      List<Map<String, dynamic>> baseList;
      switch (_currentFilter) {
        case 'active':
          baseList = _users
              .where((user) => !(user['is_blocked'] as bool))
              .toList();
          break;
        case 'blocked':
          baseList = _users
              .where((user) => user['is_blocked'] as bool)
              .toList();
          break;
        case 'admin':
          baseList = _users.where((user) {
            // is_admin hem int (1/0) hem de bool olabilir
            final isAdmin = user['is_admin'];
            return isAdmin == 1 || isAdmin == true;
          }).toList();
          break;
        default:
          baseList = _users;
      }

      // Sonra arama sorgusuna göre filtrele
      if (query.isEmpty) {
        _filteredUsers = baseList;
      } else {
        _filteredUsers = baseList.where((user) {
          final firstName = (user['first_name'] ?? '').toString().toLowerCase();
          final lastName = (user['last_name'] ?? '').toString().toLowerCase();
          final username = (user['username'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final jobTitle = (user['job_title'] ?? '').toString().toLowerCase();

          return firstName.contains(query) ||
              lastName.contains(query) ||
              username.contains(query) ||
              email.contains(query) ||
              jobTitle.contains(query);
        }).toList();
      }

      // Özel sıralama uygula
      _sortUsers(_filteredUsers);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const UserListShimmer();
    }

    return Column(
      children: [
        // Arama ve Filtre Alanı
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Gelişmiş Arama Çubuğu
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Ara',
                  hintText: 'Ad, soyad, kullanıcı adı veya meslek...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterUsers();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filtre Butonları
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    UserFilterChip(
                      label: 'Tümü',
                      value: 'all',
                      currentFilter: _currentFilter,
                      onSelected: (value) {
                        setState(() {
                          _currentFilter = value;
                          _filterUsers();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    UserFilterChip(
                      label: 'Aktif',
                      value: 'active',
                      currentFilter: _currentFilter,
                      onSelected: (value) {
                        setState(() {
                          _currentFilter = value;
                          _filterUsers();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    UserFilterChip(
                      label: 'Bloklu',
                      value: 'blocked',
                      currentFilter: _currentFilter,
                      onSelected: (value) {
                        setState(() {
                          _currentFilter = value;
                          _filterUsers();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    UserFilterChip(
                      label: 'Admin',
                      value: 'admin',
                      currentFilter: _currentFilter,
                      onSelected: (value) {
                        setState(() {
                          _currentFilter = value;
                          _filterUsers();
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_filteredUsers.length} kullanıcı',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Kullanıcı Listesi
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).iconTheme.color?.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'Arama kriterlerine uygun kullanıcı bulunamadı'
                            : 'Henüz kullanıcı bulunmuyor',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount:
                      _filteredUsers.length +
                      (_hasMore || _isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at the end
                    if (index == _filteredUsers.length) {
                      if (_isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (!_hasMore) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'Tüm kullanıcılar yüklendi',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final user = _filteredUsers[index];
                    return UserCard(
                      user: user,
                      authService: _authService,
                      onTap: () async {
                        // Direkt düzenleme dialogunu aç
                        final result = await showUserEditDialog(
                          context: context,
                          user: user,
                          authService: _authService,
                        );
                        if (result == true) {
                          _refreshSingleUser(user['id']);
                        }
                      },
                      onEdit: () async {
                        final result = await showUserEditDialog(
                          context: context,
                          user: user,
                          authService: _authService,
                        );
                        if (result == true) {
                          _refreshSingleUser(user['id']);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
