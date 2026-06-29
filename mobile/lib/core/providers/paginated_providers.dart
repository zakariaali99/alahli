import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/athlete_model.dart';
import '../models/subscription_model.dart';
import '../models/registration_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../providers/paginated_list_notifier.dart';
import '../providers/providers.dart';

class AthleteFilter {
  final String? search;
  final int? departmentId;
  final bool? isActive;

  AthleteFilter({this.search, this.departmentId, this.isActive});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AthleteFilter &&
          search == other.search &&
          departmentId == other.departmentId &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(search, departmentId, isActive);
}

final athletesPaginatedProvider = StateNotifierProvider.autoDispose
    .family<PaginatedListNotifier<AthleteModel, AthleteFilter>, PaginatedListState<AthleteModel>, AthleteFilter>((ref, filter) {
  return PaginatedListNotifier<AthleteModel, AthleteFilter>(
    params: filter,
    fetchFn: (params, page) => ref
        .watch(athleteRepositoryProvider)
        .fetchAthletesPaginated(
          search: params.search,
          departmentId: params.departmentId,
          isActive: params.isActive,
          page: page,
        ),
  );
});

class SubscriptionFilter {
  final String? status;
  final String? search;
  final int? athleteId;

  SubscriptionFilter({this.status, this.search, this.athleteId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionFilter &&
          status == other.status &&
          search == other.search &&
          athleteId == other.athleteId;

  @override
  int get hashCode => Object.hash(status, search, athleteId);
}

final subscriptionsPaginatedProvider = StateNotifierProvider.autoDispose
    .family<PaginatedListNotifier<SubscriptionModel, SubscriptionFilter>, PaginatedListState<SubscriptionModel>, SubscriptionFilter>((ref, filter) {
  return PaginatedListNotifier<SubscriptionModel, SubscriptionFilter>(
    params: filter,
    fetchFn: (params, page) => ref
        .watch(subscriptionRepositoryProvider)
        .fetchSubscriptionsPaginated(
          status: params.status,
          search: params.search,
          athleteId: params.athleteId,
          page: page,
        ),
  );
});

class RegistrationFilter {
  final String? status;
  final String? roleChoice;

  RegistrationFilter({this.status, this.roleChoice});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistrationFilter &&
          status == other.status &&
          roleChoice == other.roleChoice;

  @override
  int get hashCode => Object.hash(status, roleChoice);
}

final registrationsPaginatedProvider = StateNotifierProvider.autoDispose
    .family<PaginatedListNotifier<RegistrationModel, RegistrationFilter>, PaginatedListState<RegistrationModel>, RegistrationFilter>((ref, filter) {
  return PaginatedListNotifier<RegistrationModel, RegistrationFilter>(
    params: filter,
    fetchFn: (params, page) => ref
        .watch(registrationRepositoryProvider)
        .fetchRegistrationsPaginated(
          status: params.status,
          roleChoice: params.roleChoice,
          page: page,
        ),
  );
});

class NotificationFilter {
  final bool? unreadOnly;

  NotificationFilter({this.unreadOnly});

  static final NotificationFilter defaultFilter = NotificationFilter();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationFilter && unreadOnly == other.unreadOnly;

  @override
  int get hashCode => unreadOnly.hashCode;
}

final notificationsPaginatedProvider = StateNotifierProvider.autoDispose
    .family<PaginatedListNotifier<NotificationModel, NotificationFilter>, PaginatedListState<NotificationModel>, NotificationFilter>((ref, filter) {
  return PaginatedListNotifier<NotificationModel, NotificationFilter>(
    params: filter,
    fetchFn: (params, page) => ref
        .watch(notificationRepositoryProvider)
        .fetchNotificationsPaginated(page: page),
  );
});

class StaffFilter {
  final String? search;
  final String? role;

  StaffFilter({this.search, this.role});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffFilter &&
          search == other.search &&
          role == other.role;

  @override
  int get hashCode => Object.hash(search, role);
}

final staffPaginatedProvider = StateNotifierProvider.autoDispose
    .family<PaginatedListNotifier<UserModel, StaffFilter>, PaginatedListState<UserModel>, StaffFilter>((ref, filter) {
  return PaginatedListNotifier<UserModel, StaffFilter>(
    params: filter,
    fetchFn: (params, page) => ref
        .watch(staffRepositoryProvider)
        .fetchStaffPaginated(
          search: params.search,
          role: params.role,
          page: page,
        ),
  );
});
