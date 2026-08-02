import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import User
from apps.accounts.tests.factories import (
    AthleteFactory,
    DepartmentFactory,
    SportFactory,
    SubscriptionFactory,
    UserFactory,
)
from apps.athletes.models import RegistrationRequest
from apps.subscriptions.models import Subscription


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def special_manager():
    return UserFactory(role=User.Role.SPECIAL_MANAGER, is_staff=False)


@pytest.fixture
def manager_client(api_client, special_manager):
    refresh = RefreshToken.for_user(special_manager)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.mark.django_db
class TestSubscriptionSportFilter:
    def test_filter_subscriptions_by_sport(self, manager_client):
        dept = DepartmentFactory()
        sport_a = SportFactory(department=dept)
        sport_b = SportFactory(department=dept)
        athlete_a = AthleteFactory(department=dept, sport=sport_a)
        athlete_b = AthleteFactory(department=dept, sport=sport_b)
        SubscriptionFactory(athlete=athlete_a)
        SubscriptionFactory(athlete=athlete_b)

        response = manager_client.get(f"/api/subscriptions/?department={dept.id}&sport={sport_a.id}")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1
        assert response.data["results"][0]["athlete"] == athlete_a.id

    def test_filter_subscriptions_by_department_only(self, manager_client):
        dept = DepartmentFactory()
        athlete = AthleteFactory(department=dept)
        SubscriptionFactory(athlete=athlete)
        response = manager_client.get(f"/api/subscriptions/?department={dept.id}")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1


@pytest.mark.django_db
class TestRegistrationSportFilter:
    def test_filter_athlete_registrations_by_sport(self, manager_client):
        dept = DepartmentFactory()
        sport_a = SportFactory(department=dept)
        sport_b = SportFactory(department=dept)
        user_a = UserFactory(role=User.Role.ATHLETE, is_staff=False, academy=dept)
        user_b = UserFactory(role=User.Role.ATHLETE, is_staff=False, academy=dept)
        reg_a = RegistrationRequest.objects.create(user=user_a, role_choice="athlete", status="pending")
        reg_b = RegistrationRequest.objects.create(user=user_b, role_choice="athlete", status="pending")
        AthleteFactory(department=dept, sport=sport_a, registration=reg_a)
        AthleteFactory(department=dept, sport=sport_b, registration=reg_b)

        response = manager_client.get(f"/api/athletes/registrations/?department={dept.id}&sport={sport_a.id}")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1
        assert response.data["results"][0]["id"] == reg_a.id

    def test_filter_parent_registrations_by_sport(self, manager_client):
        dept = DepartmentFactory()
        sport_a = SportFactory(department=dept)
        sport_b = SportFactory(department=dept)
        parent_a = UserFactory(role=User.Role.PARENT, is_staff=False, academy=dept, preferred_sport=sport_a)
        parent_b = UserFactory(role=User.Role.PARENT, is_staff=False, academy=dept, preferred_sport=sport_b)
        RegistrationRequest.objects.create(user=parent_a, role_choice="parent", status="pending")
        RegistrationRequest.objects.create(user=parent_b, role_choice="parent", status="pending")

        response = manager_client.get(f"/api/athletes/registrations/?department={dept.id}&sport={sport_a.id}")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1


@pytest.mark.django_db
class TestParentWhatsappDefault:
    def test_parent_whatsapp_defaults_to_phone(self, api_client, special_manager):
        dept = DepartmentFactory()
        response = api_client.post(
            "/api/auth/register/",
            {
                "role": "parent",
                "full_name": "ولي الأمر",
                "phone": "0915555555",
                "residence": "مصراتة",
                "department": dept.id,
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED
        user = User.objects.get(phone="0915555555")
        assert user.whatsapp_phone == "0915555555"

    def test_parent_explicit_whatsapp_kept(self, api_client, special_manager):
        dept = DepartmentFactory()
        response = api_client.post(
            "/api/auth/register/",
            {
                "role": "parent",
                "full_name": "ولي الأمر",
                "phone": "0916666666",
                "whatsapp_phone": "0917777777",
                "residence": "مصراتة",
                "department": dept.id,
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED
        user = User.objects.get(phone="0916666666")
        assert user.whatsapp_phone == "0917777777"


@pytest.mark.django_db
class TestStaffChildCreation:
    def test_manager_creates_child_under_parent(self, manager_client, special_manager):
        dept = DepartmentFactory()
        sport = SportFactory(department=dept)
        parent = UserFactory(role=User.Role.PARENT, is_staff=False, academy=dept, residence="مصراتة", preferred_sport=sport)

        response = manager_client.post(
            "/api/athletes/parent/athletes/",
            {
                "parent_id": parent.id,
                "full_name": "الطفل",
                "birth_day": "10",
                "birth_month": "5",
                "birth_year": "2015",
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED

        athlete = parent.managed_athletes.first().athlete
        assert athlete.full_name == "الطفل"
        assert athlete.residence == parent.residence
        assert athlete.sport_id == sport.id
        assert athlete.department_id == dept.id
        assert athlete.is_active is True
        assert athlete.user_account.whatsapp_phone == parent.phone
        assert athlete.registration.status == RegistrationRequest.Status.APPROVED

    def test_non_staff_cannot_create_child_for_other_parent(self, api_client):
        dept = DepartmentFactory()
        parent = UserFactory(role=User.Role.PARENT, is_staff=False, academy=dept)
        other = UserFactory(role=User.Role.PARENT, is_staff=False, academy=dept)
        refresh = RefreshToken.for_user(other)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")

        response = api_client.post(
            "/api/athletes/parent/athletes/",
            {
                "parent_id": parent.id,
                "full_name": "طفل",
                "birth_day": "10",
                "birth_month": "5",
                "birth_year": "2015",
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED
        assert parent.managed_athletes.count() == 0

    def test_manager_lists_children_of_parent(self, manager_client):
        dept = DepartmentFactory()
        parent = UserFactory(role=User.Role.PARENT, is_staff=False, academy=dept)
        child = AthleteFactory(department=dept, full_name="طفل أول")
        child.parents.create(parent=parent)

        response = manager_client.get(f"/api/athletes/parent/athletes/children_of/?parent_id={parent.id}&department={dept.id}")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]["full_name"] == "طفل أول"

    def test_non_staff_cannot_list_children_of_other(self, api_client):
        dept = DepartmentFactory()
        parent = UserFactory(role=User.Role.PARENT, is_staff=False, academy=dept)
        other = UserFactory(role=User.Role.PARENT, is_staff=False, academy=dept)
        refresh = RefreshToken.for_user(other)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")

        response = api_client.get(f"/api/athletes/parent/athletes/children_of/?parent_id={parent.id}")
        assert response.status_code == status.HTTP_403_FORBIDDEN
