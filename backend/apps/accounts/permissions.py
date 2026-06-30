from rest_framework.permissions import BasePermission


def is_admin_user(user):
    return bool(user and user.is_authenticated and (user.is_superuser or user.role == "super_admin"))


class IsSuperAdmin(BasePermission):
    def has_permission(self, request, view):
        return is_admin_user(request.user)


class IsReceptionOrAbove(BasePermission):
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if is_admin_user(request.user):
            return True
        return request.user.role in ["super_admin", "reception", "academy_manager"]


class IsSuperAdminOrReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in ["GET", "HEAD", "OPTIONS"]:
            return request.user.is_authenticated
        return is_admin_user(request.user)
