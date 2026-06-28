from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import TrainerReviewViewSet, TrainerViewSet

trainer_router = DefaultRouter()
trainer_router.register(r"", TrainerViewSet, basename="trainer")

review_router = DefaultRouter()
review_router.register(r"", TrainerReviewViewSet, basename="trainer-review")

urlpatterns = [
    path("reviews/", include(review_router.urls)),
    path("", include(trainer_router.urls)),
]
