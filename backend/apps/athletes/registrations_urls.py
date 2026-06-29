from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import RegistrationRequestViewSet

router = DefaultRouter()
router.register("", RegistrationRequestViewSet, basename="registration")

urlpatterns = [
    path("", include(router.urls)),
]
