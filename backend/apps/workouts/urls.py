from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import BookingViewSet, ExerciseViewSet, WorkoutSessionViewSet

router = DefaultRouter()
router.register(r"exercises", ExerciseViewSet, basename="exercise")
router.register(r"bookings", BookingViewSet, basename="booking")

urlpatterns = [
    path("", WorkoutSessionViewSet.as_view({
        "get": "list", "post": "create",
    }), name="session-list"),
    path("<int:pk>/", WorkoutSessionViewSet.as_view({
        "get": "retrieve", "put": "update",
        "patch": "partial_update", "delete": "destroy",
    }), name="session-detail"),
    path("categories/", WorkoutSessionViewSet.as_view({
        "get": "categories",
    }), name="session-categories"),
] + router.urls
