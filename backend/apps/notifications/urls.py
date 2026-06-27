from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import AnnouncementViewSet, DeviceViewSet, NotificationViewSet

devices_router = DefaultRouter()
devices_router.register("", DeviceViewSet, basename="device")

notifications_router = DefaultRouter()
notifications_router.register("", NotificationViewSet, basename="notification")

urlpatterns = [
    path("devices/", include(devices_router.urls)),
    path("", include(notifications_router.urls)),
    path("announcements/", AnnouncementViewSet.as_view({"get": "list"}), name="announcement-list"),
]
