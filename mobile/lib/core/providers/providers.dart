import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../repositories/auth_repository.dart';
import '../repositories/athlete_repository.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/department_repository.dart';
import '../repositories/registration_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/trainer_repository.dart';
import '../repositories/staff_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/package_repository.dart';
import '../models/user_model.dart';
import '../models/athlete_model.dart';
import '../models/subscription_model.dart';
import '../models/department_model.dart';
import '../models/registration_model.dart';
import '../models/trainer_model.dart';
import '../models/package_model.dart';
import '../models/notification_model.dart';
import '../models/sport_model.dart';
import '../models/group_model.dart';
import '../models/dashboard_stats.dart';
import '../helpers/secure_storage.dart';
import '../services/push_service.dart';
import '../providers/paginated_providers.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(baseUrl: ApiEndpoints.baseUrl);

  client.setOnTokensRefreshed((access, refresh) async {
    await SecureStorage.saveTokens(access: access, refresh: refresh);
  });

  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient: ref.watch(apiClientProvider));
});

final athleteRepositoryProvider = Provider<AthleteRepository>((ref) {
  return AthleteRepository(apiClient: ref.watch(apiClientProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(apiClient: ref.watch(apiClientProvider));
});

final departmentRepositoryProvider = Provider<DepartmentRepository>((ref) {
  return DepartmentRepository(apiClient: ref.watch(apiClientProvider));
});

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepository(apiClient: ref.watch(apiClientProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(apiClient: ref.watch(apiClientProvider));
});

final trainerRepositoryProvider = Provider<TrainerRepository>((ref) {
  return TrainerRepository(apiClient: ref.watch(apiClientProvider));
});

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(apiClient: ref.watch(apiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(apiClient: ref.watch(apiClientProvider));
});

final packageRepositoryProvider = Provider<PackageRepository>((ref) {
  return PackageRepository(apiClient: ref.watch(apiClientProvider));
});

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService();
});

final authInitializedProvider = StateProvider<bool>((ref) => false);

const adminRoles = {'super_admin', 'reception', 'academy_manager'};

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthRepository authRepository;
  final NotificationRepository notificationRepository;
  final Ref ref;

  AuthNotifier({
    required this.authRepository,
    required this.notificationRepository,
    required this.ref,
  }) : super(null) {
    authRepository.apiClient.setOnUnauthorized(() {
      clearSession();
    });
    tryAutoLogin();
  }

  Future<void> tryAutoLogin() async {
    final token = await SecureStorage.getAccessToken();
    final refresh = await SecureStorage.getRefreshToken();
    if (token != null && refresh != null) {
      authRepository.apiClient.setTokens(access: token, refresh: refresh);
      try {
        final user = await authRepository.getMe();
        if (!adminRoles.contains(user.role)) {
          clearSession();
          return;
        }
        state = user;
        await _registerPushToken();
      } catch (_) {
        clearSession();
      }
    }
    ref.read(authInitializedProvider.notifier).state = true;
  }

  Future<void> login(String phone, String password, bool rememberMe) async {
    final user = await authRepository.login(phone: phone, password: password, rememberMe: rememberMe);

    if (!adminRoles.contains(user.role)) {
      await authRepository.logout();
      throw Exception('عذراً، هذا التطبيق مخصص للإدارة فقط');
    }

    state = user;
    ref.read(authInitializedProvider.notifier).state = true;
    await _registerPushToken();
  }

  Future<void> _registerPushToken() async {
    try {
      final pushService = ref.read(pushServiceProvider);
      final fcmToken = await pushService.getFCMToken();
      if (fcmToken != null) {
        await notificationRepository.registerDeviceToken(
          fcmToken: fcmToken,
          platform: 'android',
        );
      }
      pushService.setOnTokenRefresh((newToken) async {
        try {
          await notificationRepository.registerDeviceToken(
            fcmToken: newToken,
            platform: 'android',
          );
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> logout() async {
    await authRepository.logout();
    state = null;
  }

  void clearSession() {
    authRepository.apiClient.clearTokens();
    SecureStorage.clearAll();
    state = null;
    ref.read(authInitializedProvider.notifier).state = true;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier(
    authRepository: ref.watch(authRepositoryProvider),
    notificationRepository: ref.watch(notificationRepositoryProvider),
    ref: ref,
  );
});

final dashboardStatsProvider = FutureProvider.autoDispose.family<DashboardStats, int?>((ref, academyId) async {
  return ref.watch(analyticsRepositoryProvider).fetchStats(academyId: academyId);
});

final athleteDetailProvider = FutureProvider.autoDispose.family<AthleteModel, int>((ref, id) {
  return ref.watch(athleteRepositoryProvider).fetchAthlete(id);
});

final athletesProvider = FutureProvider.autoDispose.family<List<AthleteModel>, Map<String, dynamic>>((ref, params) async {
  return ref.watch(athleteRepositoryProvider).fetchAthletes(
    search: params['search'] as String?,
    departmentId: params['departmentId'] as int?,
    isActive: params['isActive'] as bool?,
  );
});

final subscriptionsProvider = FutureProvider.autoDispose.family<List<SubscriptionModel>, SubscriptionFilter>((ref, filter) async {
  return ref.watch(subscriptionRepositoryProvider).fetchSubscriptions(
    status: filter.status,
    search: filter.search,
    athleteId: filter.athleteId,
  );
});

final registrationsProvider = FutureProvider.autoDispose.family<List<RegistrationModel>, Map<String, dynamic>>((ref, params) async {
  return ref.watch(registrationRepositoryProvider).fetchRegistrations(
    status: params['status'] as String?,
    roleChoice: params['roleChoice'] as String?,
  );
});

final staffProvider = FutureProvider.autoDispose.family<List<UserModel>, Map<String, dynamic>>((ref, params) async {
  return ref.watch(staffRepositoryProvider).fetchStaff(
    search: params['search'] as String?,
    role: params['role'] as String?,
  );
});

final trainersProvider = FutureProvider.autoDispose<List<TrainerModel>>((ref) async {
  return ref.watch(trainerRepositoryProvider).fetchTrainers();
});

final departmentsProvider = FutureProvider.autoDispose<List<DepartmentModel>>((ref) async {
  return ref.watch(departmentRepositoryProvider).fetchDepartments();
});

final sportsProvider = FutureProvider.autoDispose<List<SportModel>>((ref) async {
  return ref.watch(departmentRepositoryProvider).fetchSports();
});

final groupsProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  return ref.watch(departmentRepositoryProvider).fetchGroups();
});

final packagesProvider = FutureProvider.autoDispose<List<PackageModel>>((ref) async {
  return ref.watch(packageRepositoryProvider).fetchPackages();
});

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  return ref.watch(notificationRepositoryProvider).fetchNotifications();
});
