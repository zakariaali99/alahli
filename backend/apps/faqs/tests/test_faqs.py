import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.tests.factories import UserFactory
from apps.faqs.models import FAQ


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


@pytest.fixture
def faq(db):
    return FAQ.objects.create(
        question="ما هي ساعات العمل؟",
        answer="من الساعة 6 صباحاً حتى 11 مساءً",
        order=1,
        is_active=True,
    )


@pytest.mark.django_db
class TestFAQList:
    def test_list_faqs(self, auth_client, faq):
        response = auth_client.get("/api/faqs/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1
        assert response.data["results"][0]["question"] == faq.question

    def test_list_faqs_unauthenticated(self, api_client):
        response = api_client.get("/api/faqs/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_only_active_faqs(self, auth_client, faq):
        FAQ.objects.create(question="مخفي", answer="غير نشط", is_active=False)
        response = auth_client.get("/api/faqs/")
        assert response.data["count"] == 1

    def test_faqs_ordered_by_order(self, auth_client):
        second = FAQ.objects.create(question="ثاني", answer="ثاني", order=2)
        first = FAQ.objects.create(question="أول", answer="أول", order=1)
        response = auth_client.get("/api/faqs/")
        assert response.data["results"][0]["id"] == first.id
        assert response.data["results"][1]["id"] == second.id

    def test_faq_not_found(self, auth_client):
        response = auth_client.get("/api/faqs/999/")
        assert response.status_code == status.HTTP_404_NOT_FOUND
