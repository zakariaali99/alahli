import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.tests.factories import AthleteFactory, DepartmentFactory, UserFactory
from apps.athletes.models import Athlete
from apps.trainers.models import Trainer


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def viewer_user():
    return UserFactory(viewer=True)


@pytest.fixture
def reception_user():
    return UserFactory(reception=True)


@pytest.fixture
def viewer_client(api_client, viewer_user):
    refresh = RefreshToken.for_user(viewer_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.fixture
def reception_client(api_client, reception_user):
    refresh = RefreshToken.for_user(reception_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.fixture
def athlete(db):
    return AthleteFactory()


@pytest.fixture
def dept(db):
    return DepartmentFactory()


@pytest.fixture
def athlete_user(reception_user, dept):
    athlete = Athlete.objects.create(
        full_name="موظف استقبال", phone="0930000001", gender="male",
        birth_date="2000-01-15", department=dept,
    )
    reception_user.athlete = athlete
    reception_user.save()
    return reception_user


@pytest.fixture
def athlete_reception_client(api_client, athlete_user):
    refresh = RefreshToken.for_user(athlete_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.mark.django_db
class TestAthletePermissions:
    def test_viewer_cannot_create_athlete(self, viewer_client, dept):
        response = viewer_client.post("/api/athletes/", {
            "full_name": "لاعب جديد",
            "phone": "0920000001",
            "gender": "male",
            "birth_date": "2000-01-15",
            "department": dept.id,
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_reception_can_create_athlete(self, reception_client, dept):
        response = reception_client.post("/api/athletes/", {
            "full_name": "لاعب جديد",
            "phone": "0920000001",
            "gender": "male",
            "birth_date": "2000-01-15",
            "department": dept.id,
        })
        assert response.status_code == status.HTTP_201_CREATED

    def test_viewer_can_read_athletes(self, viewer_client):
        response = viewer_client.get("/api/athletes/")
        assert response.status_code == status.HTTP_200_OK

    def test_viewer_cannot_update_athlete(self, viewer_client, dept, athlete):
        response = viewer_client.patch(f"/api/athletes/{athlete.id}/", {"full_name": "معدل"})
        assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.django_db
class TestSubscriptionPermissions:
    def test_viewer_cannot_create_subscription(self, viewer_client, athlete):
        response = viewer_client.post("/api/subscriptions/", {
            "athlete": athlete.id,
            "amount": 250,
            "start_date": "2026-06-01",
            "end_date": "2026-12-31",
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_reception_can_create_subscription(self, reception_client, athlete):
        response = reception_client.post("/api/subscriptions/", {
            "athlete": athlete.id,
            "amount": 250,
            "start_date": "2026-06-01",
            "end_date": "2026-12-31",
        })
        assert response.status_code == status.HTTP_201_CREATED


@pytest.mark.django_db
class TestAttendanceLogPermissions:
    def test_viewer_cannot_create_attendance(self, viewer_client, athlete):
        response = viewer_client.post("/attendance/", {
            "athlete": athlete.id,
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_reception_can_create_attendance(self, reception_client, athlete):
        response = reception_client.post("/attendance/", {
            "athlete": athlete.id,
        })
        assert response.status_code == status.HTTP_201_CREATED


@pytest.mark.django_db
class TestWorkoutSessionPermissions:
    def test_viewer_cannot_create_session(self, viewer_client):
        response = viewer_client.post("/api/sessions/", {
            "name": "تمرين جديد",
            "date": "2026-06-28",
            "time": "10:00",
            "duration_minutes": 60,
            "location": "صالة 1",
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_reception_can_create_session(self, reception_client):
        response = reception_client.post("/api/sessions/", {
            "name": "تمرين جديد",
            "date": "2026-06-28",
            "time": "10:00",
            "duration_minutes": 60,
            "location": "صالة 1",
        })
        assert response.status_code == status.HTTP_201_CREATED


@pytest.mark.django_db
class TestExercisePermissions:
    def test_viewer_cannot_create_exercise(self, viewer_client):
        response = viewer_client.post("/api/exercises/", {
            "title": "تمرين",
            "description": "وصف التمرين",
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_reception_can_create_exercise(self, reception_client):
        response = reception_client.post("/api/exercises/", {
            "title": "تمرين",
            "description": "وصف التمرين",
        })
        assert response.status_code == status.HTTP_201_CREATED


@pytest.mark.django_db
class TestProductPermissions:
    def test_viewer_cannot_create_product(self, viewer_client):
        response = viewer_client.post("/api/store/products/", {
            "name": "منتج",
            "price": 50,
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_reception_can_create_product(self, reception_client):
        response = reception_client.post("/api/store/products/", {
            "name": "منتج",
            "price": 50,
        })
        assert response.status_code == status.HTTP_201_CREATED


@pytest.mark.django_db
class TestTrainerPermissions:
    def test_viewer_cannot_create_trainer(self, viewer_client):
        response = viewer_client.post("/api/trainers/", {
            "full_name_ar": "مدرب جديد",
            "initials": "م.ج",
            "role": "مدرب لياقة",
            "experience_years": 5,
        })
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_reception_can_create_trainer(self, reception_client):
        response = reception_client.post("/api/trainers/", {
            "full_name_ar": "مدرب جديد",
            "initials": "م.ج",
            "role": "مدرب لياقة",
            "experience_years": 5,
        })
        assert response.status_code == status.HTTP_201_CREATED


@pytest.mark.django_db
class TestTrainerReviewPermissions:
    def test_viewer_cannot_create_review(self, viewer_client, athlete):
        trainer = Trainer.objects.create(
            full_name_ar="مدرب", initials="م.د", role="مدرب", experience_years=3
        )
        opts = viewer_client.options("/api/trainers/reviews/")
        print(f"OPTIONS: {opts.status_code} {opts.data}")
        response = viewer_client.post("/api/trainers/reviews/", {
            "trainer": trainer.id,
            "rating": 5,
        })
        print(f"POST response: {response.status_code} {response.data}")
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_reception_can_create_review(self, athlete_reception_client, athlete):
        trainer = Trainer.objects.create(
            full_name_ar="مدرب", initials="م.د", role="مدرب", experience_years=3
        )
        response = athlete_reception_client.post("/api/trainers/reviews/", {
            "trainer": trainer.id,
            "rating": 5,
        })
        assert response.status_code == status.HTTP_201_CREATED
