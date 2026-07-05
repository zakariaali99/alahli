import pytest
from datetime import date
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.tests.factories import AthleteFactory, UserFactory
from apps.athletes.models import Athlete, ParentAthlete


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def athlete_user():
    user = UserFactory()
    athlete = AthleteFactory()
    user.athlete = athlete
    user.role = "athlete"
    user.save()
    return user


@pytest.fixture
def athlete_client(api_client, athlete_user):
    refresh = RefreshToken.for_user(athlete_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.fixture
def parent_user():
    return UserFactory(role="parent")


@pytest.fixture
def parent_client(api_client, parent_user):
    refresh = RefreshToken.for_user(parent_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.fixture
def staff_user():
    return UserFactory()


@pytest.fixture
def staff_client(api_client, staff_user):
    refresh = RefreshToken.for_user(staff_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.mark.django_db
class TestAgeField:
    def test_age_computed_from_birth_date(self, staff_client):
        athlete = AthleteFactory(birth_date="2000-06-15")
        response = staff_client.get(f"/api/athletes/{athlete.id}/")
        assert response.status_code == status.HTTP_200_OK
        today = date.today()
        expected_age = today.year - 2000 - (
            (today.month, today.day) < (6, 15)
        )
        assert response.data["age"] == expected_age

    def test_age_not_in_list_view(self, staff_client):
        AthleteFactory()
        response = staff_client.get("/api/athletes/")
        assert response.status_code == status.HTTP_200_OK
        assert "age" not in response.data["results"][0]


@pytest.mark.django_db
class TestMeEndpoint:
    def test_me_returns_athlete_profile(self, athlete_client, athlete_user):
        response = athlete_client.get("/api/athletes/me/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == athlete_user.athlete.id
        assert response.data["full_name"] == athlete_user.athlete.full_name
        assert "age" in response.data

    def test_me_returns_parent_children(self, parent_client, parent_user):
        athlete = AthleteFactory()
        ParentAthlete.objects.create(parent=parent_user, athlete=athlete)
        response = parent_client.get("/api/athletes/me/")
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.data, list)
        assert len(response.data) == 1
        assert response.data[0]["id"] == athlete.id

    def test_me_unauthenticated(self, api_client):
        response = api_client.get("/api/athletes/me/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_me_no_profile(self, staff_client):
        response = staff_client.get("/api/athletes/me/")
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_me_staff_with_athlete_profile(self, staff_client, staff_user):
        athlete = AthleteFactory()
        staff_user.athlete = athlete
        staff_user.save()
        response = staff_client.get("/api/athletes/me/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == athlete.id


@pytest.mark.django_db
class TestParentChildrenEndpoint:
    def test_children_returns_linked_athletes(self, parent_client, parent_user):
        athlete = AthleteFactory()
        ParentAthlete.objects.create(parent=parent_user, athlete=athlete)
        response = parent_client.get("/api/athletes/parent/athletes/children/")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]["id"] == athlete.id
        assert "age" in response.data[0]

    def test_children_unauthenticated(self, api_client):
        response = api_client.get("/api/athletes/parent/athletes/children/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_children_no_linked_athletes(self, parent_client):
        response = parent_client.get("/api/athletes/parent/athletes/children/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data == []

    def test_children_non_parent_forbidden(self, staff_client):
        response = staff_client.get("/api/athletes/parent/athletes/children/")
        assert response.status_code == status.HTTP_200_OK
