from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework.routers import DefaultRouter

from apps.subscriptions.views import AttendanceLogViewSet

router = DefaultRouter()
router.register(r"attendance", AttendanceLogViewSet, basename="attendance")

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    path("api/auth/", include("apps.accounts.urls")),
    path("api/departments/", include("apps.departments.urls")),
    path("api/athletes/", include("apps.athletes.urls")),
    path("api/subscriptions/", include("apps.subscriptions.urls")),
    path("api/notifications/", include("apps.notifications.urls")),
    path("api/analytics/", include("apps.analytics.urls")),
    path("api/sessions/", include("apps.workouts.urls")),
    path("api/trainers/", include("apps.trainers.urls")),
    path("api/store/", include("apps.store.urls")),
    path("api/progress/", include("apps.progress.urls")),
    path("api/faqs/", include("apps.faqs.urls")),
    path("api/packages/", include("apps.packages.urls")),
    path("api/preferences/", include("apps.preferences.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
urlpatterns += router.urls
