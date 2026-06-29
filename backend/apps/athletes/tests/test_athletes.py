import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from django.contrib.auth import authenticate

from apps.accounts.tests.factories import AthleteFactory, DepartmentFactory, UserFactory
from apps.athletes.models import Athlete
from apps.accounts.models import User


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def admin_user():
    return UserFactory()


@pytest.fixture
def auth_client(api_client, admin_user):
    refresh = RefreshToken.for_user(admin_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.mark.django_db
class TestAthleteList:
    def test_list_athletes(self, auth_client):
        AthleteFactory.create_batch(3)
        response = auth_client.get("/api/athletes/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] >= 3

    def test_list_unauthenticated(self, api_client):
        response = api_client.get("/api/athletes/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_search_athletes(self, auth_client):
        AthleteFactory(full_name="أحمد محمد")
        AthleteFactory(full_name="سارة علي")
        response = auth_client.get("/api/athletes/?search=أحمد")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] >= 1


@pytest.mark.django_db
class TestAthleteCreate:
    def test_create_athlete(self, auth_client):
        dept = DepartmentFactory()
        response = auth_client.post("/api/athletes/", {
            "full_name": "لاعب جديد",
            "phone": "0911111111",
            "birth_date": "2000-01-15",
            "gender": "male",
            "department": dept.id,
        })
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["full_name"] == "لاعب جديد"
        assert Athlete.objects.count() == 1

    def test_create_athlete_missing_required(self, auth_client):
        response = auth_client.post("/api/athletes/", {})
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_create_athlete_links_user_account(self, auth_client):
        dept = DepartmentFactory()
        phone = "0912222222"

        response = auth_client.post("/api/athletes/", {
            "full_name": "لاعب رابط",
            "phone": phone,
            "birth_date": "2001-01-15",
            "gender": "male",
            "department": dept.id,
        })

        assert response.status_code == status.HTTP_201_CREATED
        athlete_id = response.data["id"]
        user = User.objects.get(phone=phone)
        assert user.role == User.Role.ATHLETE
        assert user.athlete_id == athlete_id

    def test_create_athlete_with_password_can_login(self, auth_client):
        dept = DepartmentFactory()
        phone = "0913333333"
        password = "x"

        response = auth_client.post("/api/athletes/", {
            "full_name": "لاعب بكلمة سر",
            "phone": phone,
            "birth_date": "2002-01-15",
            "gender": "male",
            "department": dept.id,
            "password": password,
        })

        assert response.status_code == status.HTTP_201_CREATED, response.data
        user = authenticate(username=phone, password=password)
        assert user is not None, f"authenticate returned None for phone={phone}"
        assert user.role == User.Role.ATHLETE
        assert user.athlete_id == response.data["id"]

    def test_create_athlete_viewer_forbidden(self, api_client):
        viewer = UserFactory(viewer=True)
        refresh = RefreshToken.for_user(viewer)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.post("/api/athletes/", {})
        assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.django_db
class TestAthleteDetail:
    def test_retrieve_athlete(self, auth_client):
        athlete = AthleteFactory()
        response = auth_client.get(f"/api/athletes/{athlete.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["full_name"] == athlete.full_name

    def test_update_athlete(self, auth_client):
        athlete = AthleteFactory()
        response = auth_client.patch(f"/api/athletes/{athlete.id}/", {
            "full_name": "اسم محدث",
        })
        assert response.status_code == status.HTTP_200_OK
        assert response.data["full_name"] == "اسم محدث"

    def test_delete_athlete(self, auth_client):
        athlete = AthleteFactory()
        response = auth_client.delete(f"/api/athletes/{athlete.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT


@pytest.mark.django_db
class TestVerify:
    def test_verify_active_membership(self, auth_client):
        athlete = AthleteFactory()
        response = auth_client.get(f"/api/athletes/verify/{athlete.membership_number}/")
        assert response.status_code == status.HTTP_200_OK

    def test_verify_not_found(self, auth_client):
        response = auth_client.get("/api/athletes/verify/NONEXISTENT/")
        assert response.status_code == status.HTTP_404_NOT_FOUND
