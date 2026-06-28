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
def admin_user():
    return UserFactory()


@pytest.fixture
def auth_client(api_client, user):
    refresh = RefreshToken.for_user(user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.fixture
def admin_auth_client(api_client, admin_user):
    refresh = RefreshToken.for_user(admin_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.fixture
def package(db):
    from apps.packages.models import SubscriptionPackage
    return SubscriptionPackage.objects.create(
        name="الباقة الذهبية",
        price=500,
        duration_days=30,
        description="باقة مميزة",
        is_active=True,
    )


@pytest.mark.django_db
class TestPackageRead:
    def test_list_packages(self, auth_client, package):
        response = auth_client.get("/api/packages/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1
        assert response.data["results"][0]["name"] == package.name

    def test_list_packages_unauthenticated(self, api_client):
        response = api_client.get("/api/packages/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_retrieve_package(self, auth_client, package):
        response = auth_client.get(f"/api/packages/{package.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["price"] == "500.00"

    def test_search_packages(self, auth_client, package):
        response = auth_client.get("/api/packages/?search=ذهبية")
        assert response.status_code == status.HTTP_200_OK


@pytest.mark.django_db
class TestPackageWrite:
    def test_create_package_reception(self, admin_auth_client, admin_user):
        admin_user.role = "reception"
        admin_user.save()
        response = admin_auth_client.post("/api/packages/", {
            "name": "الباقة الفضية",
            "price": 300,
            "duration_days": 30,
        })
        assert response.status_code == status.HTTP_201_CREATED

    def test_update_package(self, admin_auth_client, admin_user, package):
        admin_user.role = "reception"
        admin_user.save()
        response = admin_auth_client.patch(f"/api/packages/{package.id}/", {"price": 600})
        assert response.status_code == status.HTTP_200_OK
        package.refresh_from_db()
        assert package.price == 600

    def test_delete_package(self, admin_auth_client, admin_user, package):
        admin_user.role = "reception"
        admin_user.save()
        response = admin_auth_client.delete(f"/api/packages/{package.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
