import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/trainer_repository.dart';
import '../repositories/store_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/faq_repository.dart';
import '../repositories/announcement_repository.dart';
import '../repositories/package_repository.dart';
import '../repositories/review_repository.dart';
import '../repositories/preference_repository.dart';
import '../repositories/device_repository.dart';
import '../repositories/admin_repository.dart';
import '../repositories/subscription_repository.dart' show SubscriptionRepository, AthleteRepository;
import '../services/push_service.dart';
import '../models/user_model.dart';
import '../models/membership_model.dart';
import '../models/notification_model.dart';
import '../models/workout_session_model.dart';
import '../models/trainer_model.dart';
import '../models/product_model.dart';
import '../models/progress_model.dart';
import '../models/faq_model.dart';
import '../models/announcement_model.dart';
import '../models/package_model.dart';
import '../models/review_model.dart';
import '../models/preference_model.dart';
import '../models/dashboard_stats.dart';
import '../helpers/secure_storage.dart';
import '../theme/app_theme.dart';

final brandProvider = StateProvider<SportsBrand>((ref) => SportsBrand.alAhly);
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

const _defaultApiUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.22.95.35:8000/api',
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: _defaultApiUrl);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(apiClientProvider));
});

final athleteRepositoryProvider = Provider<AthleteRepository>((ref) {
  return AthleteRepository(ref.watch(apiClientProvider));
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
  final SecureStorage _storage;
  final DeviceRepository _deviceRepo;
  final PushService _pushService;

  AuthNotifier(this._repo, this._client, this._storage, this._deviceRepo, this._pushService) : super(const AuthState()) {
    _client.setOnUnauthorized(() {
      if (mounted) _clearAuth();
    });
    _client.setOnTokensRefreshed((access, refresh) {
      _storage.saveTokens(access, refresh);
    });
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    final tokens = await _storage.readTokens();
    if (tokens.access == null || tokens.refresh == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    _client.setTokens(access: tokens.access!, refresh: tokens.refresh);
    try {
      final user = await _repo.getMe();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _registerDevice();
    } catch (_) {
      await _storage.clearTokens();
      _client.clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final authRes = await _repo.login(phone, password);
      await _storage.saveTokens(authRes.access, authRes.refresh);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authRes.user,
      );
      _registerDevice();
    } on Exception catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _formatError(e),
      );
    }
  }

  Future<void> _registerDevice() async {
    final token = _pushService.fcmToken;
    if (token != null) {
      await _deviceRepo.registerToken(token, Platform.isAndroid ? 'android' : 'ios');
    }
  }

  Future<void> _clearAuth() async {
    _client.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
    await _storage.clearTokens();
  }

  Future<void> logout() async {
    _client.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
    await Future.wait([
      _storage.clearTokens(),
      _repo.logout(),
    ]);
  }

  String _formatError(Exception e) {
    if (e is DioException) {
      if (e.response?.statusCode == 401) {
        return 'رقم الهاتف أو كلمة المرور غير صحيحة';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت';
      }
    }
    return 'حدث خطأ غير متوقع. حاول مرة أخرى';
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final pushService = ref.watch(pushServiceProvider);
  return AuthNotifier(repo, client, storage, deviceRepo, pushService);
});

final subscriptionsProvider = FutureProvider<List<MembershipModel>>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).getSubscriptions();
});

final activeSubscriptionProvider = FutureProvider<MembershipModel?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(subscriptionRepositoryProvider).getActiveSubscription();
});

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(apiClientProvider));
});

final trainerRepositoryProvider = Provider<TrainerRepository>((ref) {
  return TrainerRepository(ref.watch(apiClientProvider));
});

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(ref.watch(apiClientProvider));
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(apiClientProvider));
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(apiClientProvider));
});

final workoutsProvider = FutureProvider<List<WorkoutSessionModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(workoutRepositoryProvider).getSessions();
});

final trainerProvider = FutureProvider<TrainerModel?>((ref) async {
  ref.watch(authStateProvider);
  final trainers = await ref.watch(trainerRepositoryProvider).getTrainers();
  return trainers.isNotEmpty ? trainers.first : null;
});

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(storeRepositoryProvider).getProducts();
});

final weeklyProgressProvider = FutureProvider<WeeklyProgressSummary>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(progressRepositoryProvider).getWeeklyProgress();
});

final achievementsProvider = FutureProvider<List<AchievementModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(progressRepositoryProvider).getAchievements();
});

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  return FaqRepository(ref.watch(apiClientProvider));
});

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(ref.watch(apiClientProvider));
});

final packageRepositoryProvider = Provider<PackageRepository>((ref) {
  return PackageRepository(ref.watch(apiClientProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(apiClientProvider));
});

final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return PreferenceRepository(ref.watch(apiClientProvider));
});

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService();
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.watch(apiClientProvider));
});

final faqsProvider = FutureProvider<List<FaqModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(faqRepositoryProvider).getFaqs();
});

final announcementsProvider = FutureProvider<List<AnnouncementModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(announcementRepositoryProvider).getAnnouncements();
});

final packagesProvider = FutureProvider<List<PackageModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(packageRepositoryProvider).getPackages();
});

final reviewsProvider = FutureProvider<List<ReviewModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(reviewRepositoryProvider).getReviews();
});

final preferencesProvider = FutureProvider<PreferenceModel>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(preferenceRepositoryProvider).getPreferences();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return ref.watch(adminRepositoryProvider).getDashboardStats();
});

final monthlyGrowthProvider = FutureProvider<List<MonthlyGrowth>>((ref) async {
  return ref.watch(adminRepositoryProvider).getMonthlyGrowth();
});

final revenueProvider = FutureProvider<List<RevenueData>>((ref) async {
  return ref.watch(adminRepositoryProvider).getRevenue();
});

final departmentDistProvider = FutureProvider<List<DepartmentDist>>((ref) async {
  return ref.watch(adminRepositoryProvider).getDepartmentDistribution();
});
