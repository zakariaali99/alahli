import datetime

import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.tests.factories import DepartmentFactory, UserFactory
from apps.departments.models import Group, Sport


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
class TestBankDetailsEndpoint:
    def test_bank_details_returns_department_bank_data(self, auth_client):
        department = DepartmentFactory(bank_account_number="123456789", iban="LY12BANK000000123456789")
        sport = Sport.objects.create(name="swim", name_ar="سباحة", department=department)
        group = Group.objects.create(
            name="g1",
            name_ar="المجموعة 1",
            sport=sport,
            days=["monday"],
            start_time=datetime.time(16, 0),
            end_time=datetime.time(17, 0),
        )

        response = auth_client.get(f"/api/subscriptions/bank_details/?group_id={group.id}")

        assert response.status_code == status.HTTP_200_OK
        assert response.data == {
            "account_number": "123456789",
            "iban": "LY12BANK000000123456789",
        }

    def test_bank_details_requires_group_id(self, auth_client):
        response = auth_client.get("/api/subscriptions/bank_details/")

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert response.data["detail"] == "group_id is required"
