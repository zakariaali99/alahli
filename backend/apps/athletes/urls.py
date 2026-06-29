from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import AthleteViewSet, ParentAthleteViewSet, RegistrationRequestViewSet

router = DefaultRouter()
router.register("", AthleteViewSet)

urlpatterns = [
    path("registrations/", include("apps.athletes.registrations_urls")),
    path("parent/athletes/", include("apps.athletes.parent_urls")),
    path("", include(router.urls)),
]
