from rest_framework.permissions import BasePermission, SAFE_METHODS


ADMIN_ROLES = frozenset(["super_admin", "academy_manager", "reception"])
STAFF_ROLES = frozenset(["super_admin", "academy_manager", "reception", "trainer", "viewer"])
RECOGNITION_ROLES = frozenset(["super_admin", "reception"])


def is_super_admin(user):
    return bool(user and user.is_authenticated and (user.is_superuser or user.role == "super_admin"))


def is_management_staff(user):
    return bool(user and user.is_authenticated and user.role in ADMIN_ROLES)


def is_staff_user(user):
    return bool(user and user.is_authenticated and user.role in STAFF_ROLES)


def is_recognition_staff(user):
    return bool(user and user.is_authenticated and user.role in RECOGNITION_ROLES)


def scope_by_academy(user, queryset, academy_field="department"):
    if is_super_admin(user):
        return queryset
    if user.academy:
        return queryset.filter(**{academy_field: user.academy})
    return queryset


class IsSuperAdmin(BasePermission):
    def has_permission(self, request, view):
        return is_super_admin(request.user)


class IsStaffOrAbove(BasePermission):
    def has_permission(self, request, view):
        return is_staff_user(request.user)


class IsManagementOrAbove(BasePermission):
    def has_permission(self, request, view):
        return is_management_staff(request.user)


class IsRecognitionStaff(BasePermission):
    def has_permission(self, request, view):
        return is_recognition_staff(request.user)


class IsSuperAdminOrStaffReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return is_staff_user(request.user)
        return is_super_admin(request.user)


class IsManagementOrStaffReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return is_staff_user(request.user)
        return is_management_staff(request.user)


class IsNotRejectedAccount(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        if not user.is_authenticated:
            return True
        if user.role not in ["athlete", "parent"]:
            return True
        if user.is_active:
            return True
        return False


class IsRejectedAccount(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        if not user.is_authenticated:
            return False
        if user.role not in ["athlete", "parent"]:
            return False
        if user.is_active:
            return False
        return user.registration_requests.filter(status="rejected").exists()
