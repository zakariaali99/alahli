from rest_framework.routers import DefaultRouter

from .views import TrainerViewSet

router = DefaultRouter()
router.register(r"", TrainerViewSet, basename="trainer")

urlpatterns = router.urls
