from rest_framework.routers import DefaultRouter

from .views import TrainerReviewViewSet, TrainerViewSet

router = DefaultRouter()
router.register(r"", TrainerViewSet, basename="trainer")
router.register(r"reviews", TrainerReviewViewSet, basename="trainer-review")

urlpatterns = router.urls
