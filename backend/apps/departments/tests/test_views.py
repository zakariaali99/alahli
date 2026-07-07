import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.tests.factories import DepartmentFactory, UserFactory
from apps.departments.models import Group, Sport


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
class TestSportReadAccess:
    def test_athlete_can_read_sports(self, api_client):
        dept = DepartmentFactory()
        Sport.objects.create(name="كرة قدم", department=dept, is_active=True)
        user = UserFactory(role="athlete", is_active=True)
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.get("/api/sports/", {"department": dept.id})
        assert response.status_code == status.HTTP_200_OK

    def test_athlete_cannot_create_sport(self, api_client):
        dept = DepartmentFactory()
        user = UserFactory(role="athlete", is_active=True)
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.post("/api/sports/", {
            "name": "كرة قدم",
            "name_ar": "كرة قدم",
            "department": dept.id,
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_parent_can_read_sports(self, api_client):
        dept = DepartmentFactory()
        Sport.objects.create(name="كرة سلة", department=dept, is_active=True)
        user = UserFactory(role="parent", is_active=True)
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.get("/api/sports/", {"department": dept.id})
        assert response.status_code == status.HTTP_200_OK

    def test_parent_cannot_create_sport(self, api_client):
        dept = DepartmentFactory()
        user = UserFactory(role="parent", is_active=True)
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.post("/api/sports/", {
            "name": "كرة سلة",
            "name_ar": "كرة سلة",
            "department": dept.id,
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_unauthenticated_cannot_read_sports(self, api_client):
        response = api_client.get("/api/sports/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestGroupReadAccess:
    def test_athlete_can_read_groups(self, api_client):
        dept = DepartmentFactory()
        sport = Sport.objects.create(name="كرة قدم", department=dept, is_active=True)
        Group.objects.create(name="مجموعة أ", name_ar="مجموعة أ", sport=sport, start_time="08:00", end_time="10:00", is_active=True)
        user = UserFactory(role="athlete", is_active=True)
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.get("/api/groups/", {"sport": sport.id})
        assert response.status_code == status.HTTP_200_OK

    def test_athlete_cannot_create_group(self, api_client):
        dept = DepartmentFactory()
        sport = Sport.objects.create(name="كرة قدم", department=dept, is_active=True)
        user = UserFactory(role="athlete", is_active=True)
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.post("/api/groups/", {
            "name": "مجموعة أ",
            "name_ar": "مجموعة أ",
            "sport": sport.id,
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_parent_can_read_groups(self, api_client):
        dept = DepartmentFactory()
        sport = Sport.objects.create(name="كرة سلة", department=dept, is_active=True)
        Group.objects.create(name="مجموعة ب", name_ar="مجموعة ب", sport=sport, start_time="08:00", end_time="10:00", is_active=True)
        user = UserFactory(role="parent", is_active=True)
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.get("/api/groups/", {"sport": sport.id})
        assert response.status_code == status.HTTP_200_OK

    def test_unauthenticated_cannot_read_groups(self, api_client):
        response = api_client.get("/api/groups/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
