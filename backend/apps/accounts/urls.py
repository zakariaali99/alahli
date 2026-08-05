from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from apps.athletes.views import register_view

from . import views

from .backup_views import BackupExportView, BackupImportView

router = DefaultRouter()
router.register(r"users", views.UserViewSet, basename="user")

urlpatterns = [
    path("login/", views.login_view, name="auth-login"),
    path("logout/", views.logout_view, name="auth-logout"),
    path("register/", register_view, name="auth-register"),
    path("me/", views.me_view, name="auth-me"),
    path("profile/", views.update_profile_view, name="auth-profile"),
    path("change-password/", views.change_password_view, name="auth-change-password"),
    path("delete-rejected-account/", views.delete_rejected_account_view, name="auth-delete-rejected-account"),
    path("backup/export/", BackupExportView.as_view(), name="backup-export"),
    path("backup/import/", BackupImportView.as_view(), name="backup-import"),
    path("token/", TokenObtainPairView.as_view(), name="token-obtain"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("", include(router.urls)),
]
