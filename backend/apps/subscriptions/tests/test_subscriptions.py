import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.tests.factories import (
    AthleteFactory,
    SubscriptionFactory,
    UserFactory,
)
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
