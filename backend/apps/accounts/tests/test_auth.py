import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

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
