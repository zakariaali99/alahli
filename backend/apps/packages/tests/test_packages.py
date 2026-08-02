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
        duration_type="months",
        duration_value=1,
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

    def test_athlete_can_read_packages(self, api_client, package):
        athlete = UserFactory(role="athlete", is_active=True)
        refresh = RefreshToken.for_user(athlete)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.get("/api/packages/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1

    def test_parent_can_read_packages(self, api_client, package):
        parent = UserFactory(role="parent", is_active=True)
        refresh = RefreshToken.for_user(parent)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.get("/api/packages/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1

    def test_filter_packages_by_sport(self, auth_client, db):
        from apps.departments.models import Department, Sport
        from apps.packages.models import SubscriptionPackage
        dept = Department.objects.create(name="Dept A", name_ar="قسم أ")
        sport1 = Sport.objects.create(name="Karate", name_ar="كاراتيه", department=dept)
        sport2 = Sport.objects.create(name="Football", name_ar="كرة قدم", department=dept)

        pkg_karate = SubscriptionPackage.objects.create(
            name="باقة كاراتيه", price=300, department=dept, sport=sport1, is_active=True
        )
        pkg_football = SubscriptionPackage.objects.create(
            name="باقة كرة قدم", price=400, department=dept, sport=sport2, is_active=True
        )
        pkg_general = SubscriptionPackage.objects.create(
            name="باقة عامة", price=200, department=dept, sport=null if False else None, is_active=True
        )

        res = auth_client.get(f"/api/packages/?department={dept.id}&sport={sport1.id}")
        assert res.status_code == status.HTTP_200_OK
        results = res.data["results"]
        ids = [p["id"] for p in results]
        assert pkg_karate.id in ids
        assert pkg_general.id in ids
        assert pkg_football.id not in ids


@pytest.mark.django_db
class TestPackageWrite:
    def test_create_package_super_admin(self, admin_auth_client, admin_user):
        admin_user.role = "super_admin"
        admin_user.save()
        response = admin_auth_client.post("/api/packages/", {
            "name": "الباقة الفضية",
            "price": 300,
            "duration_type": "months",
            "duration_value": 1,
        })
        assert response.status_code == status.HTTP_201_CREATED

    def test_update_package(self, admin_auth_client, admin_user, package):
        admin_user.role = "super_admin"
        admin_user.save()
        response = admin_auth_client.patch(f"/api/packages/{package.id}/", {"price": 600})
        assert response.status_code == status.HTTP_200_OK
        package.refresh_from_db()
        assert package.price == 600

    def test_delete_package(self, admin_auth_client, admin_user, package):
        admin_user.role = "super_admin"
        admin_user.save()
        response = admin_auth_client.delete(f"/api/packages/{package.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT

    def test_athlete_cannot_create_package(self, api_client, package):
        athlete = UserFactory(role="athlete", is_active=True)
        refresh = RefreshToken.for_user(athlete)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.post("/api/packages/", {
            "name": "الباقة الممنوعة",
            "price": 100,
            "duration_type": "months",
            "duration_value": 1,
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_parent_cannot_create_package(self, api_client, package):
        parent = UserFactory(role="parent", is_active=True)
        refresh = RefreshToken.for_user(parent)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        response = api_client.post("/api/packages/", {
            "name": "الباقة الممنوعة",
            "price": 100,
            "duration_type": "months",
            "duration_value": 1,
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN
