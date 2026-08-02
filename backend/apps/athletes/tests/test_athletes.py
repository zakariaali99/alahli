import pytest
from unittest import mock
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from django.contrib.auth import authenticate

from apps.accounts.tests.factories import AthleteFactory, DepartmentFactory, UserFactory
from apps.athletes.models import Athlete
from apps.accounts.models import User
from apps.athletes.models import RegistrationRequest


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

    def test_retrieve_athlete_with_data_url_photo_does_not_build_media_path(self, auth_client):
        athlete = AthleteFactory(photo="data:image/jpeg;base64,dGVzdA==")
        response = auth_client.get(f"/api/athletes/{athlete.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["photo"] == "data:image/jpeg;base64,dGVzdA=="


@pytest.mark.django_db
class TestVerify:
    def test_verify_active_membership(self, auth_client):
        athlete = AthleteFactory()
        response = auth_client.get(f"/api/athletes/verify/{athlete.membership_number}/")
        assert response.status_code == status.HTTP_200_OK

    def test_verify_not_found(self, auth_client):
        response = auth_client.get("/api/athletes/verify/NONEXISTENT/")
        assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.django_db
class TestRegistrationAPI:
    def test_register_duplicate_phone(self, api_client):
        UserFactory(phone="0911234567")
        response = api_client.post("/api/auth/register/", {
            "role": "athlete",
            "full_name": "لاعب جديد",
            "phone": "0911234567",
            "password": "password123",
            "photo": "data:image/jpeg;base64,dGVzdA==",
            "birth_day": 1,
            "birth_month": 1,
            "birth_year": 2000,
        })
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "phone" in response.data["detail"]

    @mock.patch("apps.notifications.services.send_admin_push_sync")
    def test_register_notifications_parent_vs_athlete(self, mock_send, api_client):
        # 1. Register Athlete
        response = api_client.post("/api/auth/register/", {
            "role": "athlete",
            "full_name": "لاعب جديد",
            "phone": "0912222222",
            "password": "password123",
            "photo": "data:image/jpeg;base64,dGVzdA==",
            "birth_day": 1,
            "birth_month": 1,
            "birth_year": 2000,
        })
        assert response.status_code == status.HTTP_201_CREATED
        mock_send.assert_called_with(
            title="تسجيل رياضي جديد",
            body="طلب تسجيل جديد من رياضي لاعب جديد - 0912222222",
            notification_type="new_registration",
            entity_id=response.data["registration_id"]
        )

        # 2. Register Parent
        mock_send.reset_mock()
        response = api_client.post("/api/auth/register/", {
            "role": "parent",
            "full_name": "ولي أمر جديد",
            "phone": "0913333333",
            "password": "password123",
            "birth_day": 1,
            "birth_month": 1,
            "birth_year": 1980,
        })
        assert response.status_code == status.HTTP_201_CREATED
        mock_send.assert_called_with(
            title="تسجيل ولي أمر جديد",
            body="طلب تسجيل جديد من ولي أمر ولي أمر جديد - 0913333333",
            notification_type="new_registration",
            entity_id=response.data["registration_id"]
        )


@pytest.mark.django_db
class TestParentUpdate:
    def _register_parent(self, api_client, phone="0914444444"):
        response = api_client.post("/api/auth/register/", {
            "role": "parent",
            "full_name": "ولي أمر قديم",
            "phone": phone,
            "password": "password123",
            "birth_day": 1,
            "birth_month": 1,
            "birth_year": 1980,
            "residence": "طرابلس",
        })
        assert response.status_code == status.HTTP_201_CREATED
        return response.data["registration_id"]

    def test_update_parent(self, api_client, auth_client):
        reg_id = self._register_parent(api_client)
        response = auth_client.patch(f"/api/athletes/registrations/{reg_id}/parent-update/", {
            "full_name": "ولي أمر محدث",
            "whatsapp_phone": "0915555555",
            "residence": "بنغازي",
        })
        assert response.status_code == status.HTTP_200_OK
        reg = RegistrationRequest.objects.get(id=reg_id)
        assert reg.user.full_name_ar == "ولي أمر محدث"
        assert reg.user.phone == "0915555555"
        assert reg.residence == "بنغازي"

    def test_update_parent_rejects_non_parent(self, api_client, auth_client):
        response = api_client.post("/api/auth/register/", {
            "role": "athlete",
            "full_name": "لاعب تعديل",
            "phone": "0916666666",
            "password": "password123",
            "photo": "data:image/jpeg;base64,dGVzdA==",
            "birth_day": 1,
            "birth_month": 1,
            "birth_year": 2000,
        })
        reg_id = response.data["registration_id"]
        res = auth_client.patch(f"/api/athletes/registrations/{reg_id}/parent-update/", {
            "full_name": "اسم جديد",
        })
        assert res.status_code == status.HTTP_400_BAD_REQUEST

    def test_update_parent_duplicate_phone(self, api_client, auth_client):
        UserFactory(phone="0917777777")
        reg_id = self._register_parent(api_client)
        response = auth_client.patch(f"/api/athletes/registrations/{reg_id}/parent-update/", {
            "whatsapp_phone": "0917777777",
        })
        assert response.status_code == status.HTTP_400_BAD_REQUEST
