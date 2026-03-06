import '../../../domain/entities/notification.dart';

/// Ana ekran state'i
/// Home ekranının durumunu yönetir.
class HomeState {
  final int selectedTab;
  final List<Notification> notifications;
  final bool isUserBlocked;
  final bool isLoading;
  final String? errorMessage;

  const HomeState({
    this.selectedTab = 0,
    this.notifications = const [],
    this.isUserBlocked = false,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Initial state
  factory HomeState.initial() => const HomeState();

  /// Copy with method
  HomeState copyWith({
    int? selectedTab,
    List<Notification>? notifications,
    bool? isUserBlocked,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      selectedTab: selectedTab ?? this.selectedTab,
      notifications: notifications ?? this.notifications,
      isUserBlocked: isUserBlocked ?? this.isUserBlocked,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
