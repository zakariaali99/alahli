enum AppAction {
  athletesRead,
  athletesCreate,
  athletesUpdate,
  athletesDelete,
  subscriptionsRead,
  subscriptionsCreate,
  subscriptionsUpdate,
  subscriptionsDelete,
  subscriptionsRenew,
  packagesCreate,
  packagesUpdate,
  packagesDelete,
  departmentsCreate,
  departmentsUpdate,
  departmentsDelete,
  staffRead,
  staffCreate,
  staffUpdate,
  staffDelete,
  coachesRead,
  coachesCreate,
  coachesUpdate,
  coachesDelete,
  registrationsRead,
  registrationsApprove,
  registrationsReject,
  settingsUpdate,
  reportsRead,
  notificationsRead,
  notificationsCreate,
  notificationsDelete,
  verifyRead,
  analyticsRead,
}

class Permissions {
  static const Map<AppAction, List<String>> _actions = {
    AppAction.athletesRead: [
      'super_admin', 'academy_manager', 'reception', 'trainer', 'viewer',
    ],
    AppAction.athletesCreate: ['super_admin', 'academy_manager'],
    AppAction.athletesUpdate: ['super_admin', 'academy_manager'],
    AppAction.athletesDelete: ['super_admin'],

    AppAction.subscriptionsRead: [
      'super_admin', 'academy_manager', 'reception', 'trainer', 'viewer',
      'athlete', 'parent',
    ],
    AppAction.subscriptionsCreate: ['super_admin', 'academy_manager'],
    AppAction.subscriptionsUpdate: ['super_admin', 'academy_manager'],
    AppAction.subscriptionsDelete: ['super_admin'],
    AppAction.subscriptionsRenew: ['super_admin', 'academy_manager'],

    AppAction.packagesCreate: ['super_admin', 'academy_manager'],
    AppAction.packagesUpdate: ['super_admin', 'academy_manager'],
    AppAction.packagesDelete: ['super_admin'],

    AppAction.departmentsCreate: ['super_admin', 'academy_manager'],
    AppAction.departmentsUpdate: ['super_admin', 'academy_manager'],
    AppAction.departmentsDelete: ['super_admin'],

    AppAction.staffRead: ['super_admin', 'academy_manager'],
    AppAction.staffCreate: ['super_admin'],
    AppAction.staffUpdate: ['super_admin'],
    AppAction.staffDelete: ['super_admin'],

    AppAction.coachesRead: [
      'super_admin', 'academy_manager', 'reception', 'trainer', 'viewer',
    ],
    AppAction.coachesCreate: ['super_admin', 'academy_manager'],
    AppAction.coachesUpdate: ['super_admin', 'academy_manager'],
    AppAction.coachesDelete: ['super_admin'],

    AppAction.registrationsRead: ['super_admin', 'academy_manager'],
    AppAction.registrationsApprove: ['super_admin', 'academy_manager'],
    AppAction.registrationsReject: ['super_admin', 'academy_manager'],

    AppAction.settingsUpdate: ['super_admin'],

    AppAction.reportsRead: ['super_admin', 'academy_manager'],

    AppAction.notificationsRead: [
      'super_admin', 'academy_manager', 'reception', 'trainer', 'viewer',
    ],
    AppAction.notificationsCreate: ['super_admin'],
    AppAction.notificationsDelete: ['super_admin'],

    AppAction.verifyRead: [
      'super_admin', 'academy_manager', 'reception', 'trainer', 'viewer',
    ],
    AppAction.analyticsRead: [
      'super_admin', 'academy_manager', 'reception', 'trainer', 'viewer',
    ],
  };

  static bool can(String? role, AppAction action) {
    if (role == null) return false;
    final roles = _actions[action];
    if (roles == null) return false;
    return roles.contains(role);
  }

  static String roleLabel(String? role) {
    switch (role) {
      case 'super_admin':
        return 'مدير النظام';
      case 'academy_manager':
        return 'مدير الأكاديمية';
      case 'reception':
        return 'موظف استقبال';
      case 'trainer':
        return 'مدرب';
      case 'viewer':
        return 'مشاهد';
      case 'athlete':
        return 'لاعب';
      case 'parent':
        return 'ولي أمر';
      default:
        return 'مشاهد';
    }
  }
}
