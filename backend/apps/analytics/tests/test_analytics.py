import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.tests.factories import AthleteFactory, RenewalFactory, SubscriptionFactory, UserFactory


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


@pytest.mark.django_db
class TestDashboardStats:
    def test_stats_authenticated(self, auth_client):
        athlete = AthleteFactory()
        SubscriptionFactory(athlete=athlete)
        response = auth_client.get("/api/analytics/stats/")
        assert response.status_code == status.HTTP_200_OK
        assert "total_athletes" in response.data
        assert "active_memberships" in response.data
        assert "expired_memberships" in response.data
        assert "expiring_soon" in response.data
        assert "new_this_month" in response.data

    def test_stats_unauthenticated(self, api_client):
        response = api_client.get("/api/analytics/stats/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_stats_revenue_includes_renewals(self, auth_client):
        athlete = AthleteFactory()
        sub = SubscriptionFactory(athlete=athlete, amount=500)
        RenewalFactory(subscription=sub, amount=200)
        response = auth_client.get("/api/analytics/stats/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["total_revenue"] == 700.0

    def test_stats_revenue_without_renewals(self, auth_client):
        athlete = AthleteFactory()
        SubscriptionFactory(athlete=athlete, amount=300)
        response = auth_client.get("/api/analytics/stats/")
        assert response.data["total_revenue"] == 300.0


@pytest.mark.django_db
class TestMonthlyGrowth:
    def test_monthly_growth(self, auth_client):
        AthleteFactory()
        response = auth_client.get("/api/analytics/monthly-growth/")
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.data, list)


@pytest.mark.django_db
class TestDepartmentDistribution:
    def test_department_distribution(self, auth_client):
        AthleteFactory()
        response = auth_client.get("/api/analytics/department-distribution/")
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.data, list)


@pytest.mark.django_db
class TestRevenueByMonth:
    def test_revenue_by_month_combines_subscriptions_and_renewals(self, auth_client):
        athlete = AthleteFactory()
        sub = SubscriptionFactory(athlete=athlete, amount=1000)
        RenewalFactory(subscription=sub, amount=500)
        response = auth_client.get("/api/analytics/revenue/")
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.data, list)
        assert len(response.data) >= 1
        assert response.data[0]["revenue"] == 1500.0

    def test_revenue_by_month_empty(self, auth_client):
        response = auth_client.get("/api/analytics/revenue/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data == []
