from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import SportViewSet

router = DefaultRouter()
router.register("", SportViewSet, basename="sport")

urlpatterns = [
    path("", include(router.urls)),
]
