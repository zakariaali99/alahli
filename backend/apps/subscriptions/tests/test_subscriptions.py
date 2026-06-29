import pytest
from apps.athletes.models import Athlete, RegistrationRequest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.tests.factories import (
    AthleteFactory,
    DepartmentFactory,
    SubscriptionFactory,
    UserFactory,
)
from apps.departments.models import Group, Sport
from apps.packages.models import SubscriptionPackage
from apps.subscriptions.models import Subscription


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def reception_user():
    return UserFactory(reception=True)


@pytest.fixture
def auth_client(api_client, reception_user):
    refresh = RefreshToken.for_user(reception_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.mark.django_db
class TestSubscriptionList:
    def test_list_subscriptions(self, auth_client):
        athlete = AthleteFactory()
        SubscriptionFactory(athlete=athlete)
        SubscriptionFactory(athlete=athlete)
        response = auth_client.get("/api/subscriptions/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] >= 2

    def test_list_unauthenticated(self, api_client):
        response = api_client.get("/api/subscriptions/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestSubscriptionCreate:
    def test_create_subscription(self, auth_client):
        athlete = AthleteFactory()
        response = auth_client.post("/api/subscriptions/", {
            "athlete": athlete.id,
            "start_date": "2026-01-01",
            "end_date": "2026-06-30",
            "amount": "250.00",
        })
        assert response.status_code == status.HTTP_201_CREATED
        assert Subscription.objects.count() == 1

    def test_create_subscription_missing_fields(self, auth_client):
        response = auth_client.post("/api/subscriptions/", {})
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestSubscriptionRenew:
    def test_renew_subscription(self, auth_client):
        sub = SubscriptionFactory()
        response = auth_client.post(f"/api/subscriptions/{sub.id}/renew/", {
            "months": 6,
            "amount": "300.00",
        })
        assert response.status_code == status.HTTP_200_OK

    def test_renew_invalid_months(self, auth_client):
        sub = SubscriptionFactory()
        response = auth_client.post(f"/api/subscriptions/{sub.id}/renew/", {
            "months": 7,
            "amount": "300.00",
        })
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_renew_viewer_forbidden(self, api_client):
        viewer = UserFactory(viewer=True)
        refresh = RefreshToken.for_user(viewer)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        sub = SubscriptionFactory()
        response = api_client.post(f"/api/subscriptions/{sub.id}/renew/", {
            "months": 6,
            "amount": "300.00",
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.django_db
class TestSubscriptionCheckoutAthleteFallback:
    def test_checkout_links_user_to_registration_athlete_when_user_athlete_null(self, api_client):
        athlete_user = UserFactory(role="athlete", is_staff=False)
        refresh = RefreshToken.for_user(athlete_user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")

        department = DepartmentFactory()
        sport = Sport.objects.create(name="swim", name_ar="سباحة", department=department)
        group = Group.objects.create(
            name="g1",
            name_ar="المجموعة 1",
            sport=sport,
            days=["monday"],
            start_time="16:00",
            end_time="17:00",
        )
        package = SubscriptionPackage.objects.create(
            name="Basic",
            price="100.00",
            duration_type="months",
            duration_value=1,
            max_athletes=1,
        )

        registration = RegistrationRequest.objects.create(user=athlete_user, role_choice=RegistrationRequest.RoleChoice.ATHLETE)
        athlete_profile = Athlete.objects.create(
            full_name="لاعب اختبار",
            phone=athlete_user.phone,
            birth_date="2005-01-01",
            gender="male",
            department=department,
            registration=registration,
            is_active=False,
        )

        response = api_client.post(
            "/api/subscriptions/checkout/",
            {
                "sport_id": sport.id,
                "group_id": group.id,
                "package_id": package.id,
                "payment_method": "cash",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        athlete_user.refresh_from_db()
        assert athlete_user.athlete_id == athlete_profile.id

    def test_checkout_links_user_to_athlete_by_phone_when_registration_not_linked(self, api_client):
        athlete_user = UserFactory(role="athlete", is_staff=False)
        refresh = RefreshToken.for_user(athlete_user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")

        department = DepartmentFactory()
        sport = Sport.objects.create(name="karate", name_ar="كاراتيه", department=department)
        group = Group.objects.create(
            name="g2",
            name_ar="المجموعة 2",
            sport=sport,
            days=["tuesday"],
            start_time="16:00",
            end_time="17:00",
        )
        package = SubscriptionPackage.objects.create(
            name="Basic 2",
            price="120.00",
            duration_type="months",
            duration_value=1,
            max_athletes=1,
        )

        athlete_profile = Athlete.objects.create(
            full_name="لاعب مطابق للهاتف",
            phone=athlete_user.phone,
            birth_date="2004-01-01",
            gender="male",
            department=department,
            is_active=False,
        )

        response = api_client.post(
            "/api/subscriptions/checkout/",
            {
                "sport_id": sport.id,
                "group_id": group.id,
                "package_id": package.id,
                "payment_method": "cash",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        athlete_user.refresh_from_db()
        assert athlete_user.athlete_id == athlete_profile.id

    def test_checkout_works_when_user_has_athlete(self, api_client):
        department = DepartmentFactory()
        sport = Sport.objects.create(name="judo", name_ar="جودو", department=department)
        group = Group.objects.create(
            name="g3", name_ar="المجموعة 3", sport=sport,
            days=["wednesday"], start_time="16:00", end_time="17:00",
        )
        package = SubscriptionPackage.objects.create(
            name="Basic 3", price="100.00",
            duration_type="months", duration_value=1, max_athletes=1,
        )

        athlete = AthleteFactory(department=department, is_active=True)
        user = athlete.user
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")

        response = api_client.post(
            "/api/subscriptions/checkout/",
            {
                "sport_id": sport.id,
                "group_id": group.id,
                "package_id": package.id,
                "payment_method": "cash",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["status"] == "pending"
