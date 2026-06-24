from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import AchievementViewSet, WeeklyProgressViewSet

router = DefaultRouter()
router.register(r"weekly", WeeklyProgressViewSet, basename="weekly-progress")
router.register(r"achievements", AchievementViewSet, basename="achievement")

urlpatterns = router.urls
