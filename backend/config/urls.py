from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

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
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
