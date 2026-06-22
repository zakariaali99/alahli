import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/notification_repository.dart';
import '../models/user_model.dart';
import '../models/membership_model.dart';
import '../models/notification_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(apiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final ApiClient _client;

  AuthNotifier(this._repo, this._client) : super(const AuthState()) {
    _client.setOnUnauthorized(() {
      if (mounted) {
        _clearAuth();
      }
    });
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final authRes = await _repo.login(phone, password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authRes.user,
      );
    } on Exception catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _formatError(e),
      );
    }
  }

  void _clearAuth() {
    _client.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _formatError(Exception e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('Invalid')) {
      return 'رقم الهاتف أو كلمة المرور غير صحيحة';
    }
    if (msg.contains('Connection refused') || msg.contains('SocketException')) {
      return 'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت';
    }
    return 'حدث خطأ غير متوقع. حاول مرة أخرى';
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(repo, client);
});

final subscriptionsProvider = FutureProvider<List<MembershipModel>>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).getSubscriptions();
});

final activeSubscriptionProvider = FutureProvider<MembershipModel?>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).getActiveSubscription();
});

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});
