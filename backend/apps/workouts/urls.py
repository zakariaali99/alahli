from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import BookingViewSet, ExerciseViewSet, WorkoutSessionViewSet

router = DefaultRouter()
router.register(r"sessions", WorkoutSessionViewSet, basename="session")
router.register(r"exercises", ExerciseViewSet, basename="exercise")
router.register(r"bookings", BookingViewSet, basename="booking")

urlpatterns = [
    path("", include(router.urls)),
]
