import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.tests.factories import UserFactory


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user():
    return UserFactory()


@pytest.fixture
def auth_client(api_client, user):
    refresh = RefreshToken.for_user(user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


PREF_URL = "/api/preferences/"
PREF_DETAIL_URL = "/api/preferences/1/"


@pytest.mark.django_db
class TestPreferencesRead:
    def test_get_preferences_creates_on_first_access(self, auth_client):
        response = auth_client.get(PREF_URL)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["language"] == "ar"
        assert response.data["theme"] == "light"
        assert response.data["notifications_enabled"] is True

    def test_get_preferences_unauthenticated(self, api_client):
        response = api_client.get(PREF_URL)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_preferences_isolated_per_user(self, auth_client, user):
        response = auth_client.get(PREF_URL)
        assert response.data["language"] == "ar"
        other = UserFactory(phone="0920000001")
        other_refresh = RefreshToken.for_user(other)
        other_client = APIClient()
        other_client.credentials(HTTP_AUTHORIZATION=f"Bearer {other_refresh.access_token}")
        other_response = other_client.get(PREF_URL)
        assert other_response.data["language"] == "ar"


@pytest.mark.django_db
class TestPreferencesUpdate:
    def test_update_preferences(self, auth_client):
        response = auth_client.patch(PREF_DETAIL_URL, {
            "language": "en",
            "theme": "dark",
            "notifications_enabled": False,
        })
        assert response.status_code == status.HTTP_200_OK
        assert response.data["language"] == "en"
        assert response.data["theme"] == "dark"
        assert response.data["notifications_enabled"] is False

    def test_update_persists(self, auth_client):
        auth_client.patch(PREF_DETAIL_URL, {"language": "en"})
        response = auth_client.get(PREF_URL)
        assert response.data["language"] == "en"

    def test_partial_update(self, auth_client):
        response = auth_client.patch(PREF_DETAIL_URL, {"theme": "dark"})
        assert response.status_code == status.HTTP_200_OK
        assert response.data["theme"] == "dark"
        assert response.data["language"] == "ar"

    def test_update_unauthenticated(self, api_client):
        response = api_client.patch(PREF_DETAIL_URL, {"language": "en"})
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_post_not_allowed(self, auth_client):
        response = auth_client.post(PREF_URL, {"language": "en"})
        assert response.status_code == status.HTTP_405_METHOD_NOT_ALLOWED
