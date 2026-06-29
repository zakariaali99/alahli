from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import ParentAthleteViewSet

router = DefaultRouter()
router.register("", ParentAthleteViewSet, basename="parent-athlete")

urlpatterns = [
    path("", include(router.urls)),
]
