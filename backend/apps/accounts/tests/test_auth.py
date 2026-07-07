import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import User

from .factories import UserFactory


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user():
    return UserFactory()


@pytest.fixture
def admin_user():
    return UserFactory()


@pytest.fixture
def auth_client(api_client, user):
    refresh = RefreshToken.for_user(user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.mark.django_db
class TestLogin:
    def test_login_success(self, api_client, user):
        response = api_client.post("/api/auth/login/", {
            "phone": user.phone,
            "password": "testpass123",
        })
        assert response.status_code == status.HTTP_200_OK
        assert "access" in response.data
        assert "refresh" in response.data
        assert "user" in response.data
        assert response.data["user"]["phone"] == user.phone

    def test_login_invalid_password(self, api_client, user):
        response = api_client.post("/api/auth/login/", {
            "phone": user.phone,
            "password": "wrongpassword",
        })
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_login_missing_fields(self, api_client):
        response = api_client.post("/api/auth/login/", {})
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestMe:
    def test_me_authenticated(self, auth_client, user):
        response = auth_client.get("/api/auth/me/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["phone"] == user.phone
        assert response.data["full_name_ar"] == user.full_name_ar

    def test_me_unauthenticated(self, api_client):
        response = api_client.get("/api/auth/me/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestChangePassword:
    def test_change_password_success(self, auth_client, user):
        user.set_password("oldpass123")
        user.save()
        response = auth_client.post("/api/auth/change-password/", {
            "old_password": "oldpass123",
            "new_password": "newpass12345",
        })
        assert response.status_code == status.HTTP_200_OK

    def test_change_password_wrong_old(self, auth_client):
        response = auth_client.post("/api/auth/change-password/", {
            "old_password": "wrong",
            "new_password": "newpass12345",
        })
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestLogout:
    def test_logout_success(self, auth_client, user):
        refresh = RefreshToken.for_user(user)
        response = auth_client.post("/api/auth/logout/", {
            "refresh": str(refresh),
        })
        assert response.status_code == status.HTTP_200_OK


@pytest.mark.django_db
class TestRejectedRegistrationFlow:
    @pytest.fixture
    def rejected_registration(self, db):
        from apps.athletes.models import RegistrationRequest, Athlete
        user = UserFactory(role=User.Role.ATHLETE, is_active=False, is_staff=False)
        registration = RegistrationRequest.objects.create(
            user=user,
            role_choice=RegistrationRequest.RoleChoice.ATHLETE,
            status=RegistrationRequest.Status.REJECTED,
            rejection_reason="بيانات غير مكتملة",
        )
        Athlete.objects.create(
            full_name="لاعب مرفوض",
            phone=user.phone,
            birth_date="2000-01-15",
            gender="male",
            is_active=False,
            registration=registration,
        )
        user.athlete = Athlete.objects.get(registration=registration)
        user.save(update_fields=["athlete"])
        return registration

    def test_rejected_user_can_login(self, api_client, rejected_registration):
        user = rejected_registration.user
        response = api_client.post("/api/auth/login/", {
            "phone": user.phone,
            "password": "testpass123",
        })
        assert response.status_code == status.HTTP_200_OK
        assert "access" in response.data

    def test_rejected_user_sees_registration_status_in_me(self, api_client, rejected_registration):
        user = rejected_registration.user
        login_resp = api_client.post("/api/auth/login/", {
            "phone": user.phone,
            "password": "testpass123",
        })
        token = login_resp.data["access"]
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        response = api_client.get("/api/auth/me/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["registration_status"] == "rejected"
        assert response.data["registration_rejection_reason"] == "بيانات غير مكتملة"

    def test_rejected_user_cannot_access_normal_endpoints(self, api_client, rejected_registration):
        user = rejected_registration.user
        login_resp = api_client.post("/api/auth/login/", {
            "phone": user.phone,
            "password": "testpass123",
        })
        token = login_resp.data["access"]
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        response = api_client.get("/api/athletes/")
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_rejected_user_can_delete_account(self, api_client, rejected_registration):
        user = rejected_registration.user
        login_resp = api_client.post("/api/auth/login/", {
            "phone": user.phone,
            "password": "testpass123",
        })
        token = login_resp.data["access"]
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        response = api_client.post("/api/auth/delete-rejected-account/")
        assert response.status_code == status.HTTP_200_OK
        assert "تم حذف" in response.data["detail"]
        from apps.accounts.models import User
        from apps.athletes.models import RegistrationRequest, Athlete
        assert not RegistrationRequest.objects.filter(id=rejected_registration.id).exists()
        assert not User.objects.filter(id=user.id).exists()
        assert not Athlete.objects.filter(registration=rejected_registration).exists()

    def test_inactive_user_without_rejected_registration_cannot_login(self, api_client):
        user = UserFactory(role=User.Role.ATHLETE, is_active=False, is_staff=False)
        response = api_client.post("/api/auth/login/", {
            "phone": user.phone,
            "password": "testpass123",
        })
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        assert "قيد المراجعة" in response.data["detail"]

    def test_duplicate_phone_with_rejected_user_returns_clear_message(self, api_client, rejected_registration):
        user = rejected_registration.user
        response = api_client.post("/api/auth/register/", {
            "role": "athlete",
            "full_name": "مستخدم جديد",
            "phone": user.phone,
            "password": "password123",
            "photo": "data:image/jpeg;base64,dGVzdA==",
            "birth_day": 1,
            "birth_month": 1,
            "birth_year": 2000,
        })
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "مرفوض" in str(response.data["detail"].get("phone", ""))

    def test_re_register_same_phone_after_delete(self, api_client, rejected_registration):
        user = rejected_registration.user
        login_resp = api_client.post("/api/auth/login/", {
            "phone": user.phone,
            "password": "testpass123",
        })
        token = login_resp.data["access"]
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        delete_resp = api_client.post("/api/auth/delete-rejected-account/")
        assert delete_resp.status_code == status.HTTP_200_OK

        api_client.credentials()
        response = api_client.post("/api/auth/register/", {
            "role": "athlete",
            "full_name": "مستخدم معاد",
            "phone": user.phone,
            "password": "newpass123",
            "photo": "data:image/jpeg;base64,dGVzdA==",
            "birth_day": 1,
            "birth_month": 1,
            "birth_year": 2000,
        })
        assert response.status_code == status.HTTP_201_CREATED
