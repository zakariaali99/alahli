from unittest.mock import patch

import pytest
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import User
from apps.accounts.tests.factories import UserFactory
from apps.notifications.models import Device
from apps.notifications.tasks import send_admin_push_notification


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def admin_user():
    return UserFactory()


@pytest.fixture
def reception_user():
    return UserFactory(reception=True)


@pytest.fixture
def viewer_user():
    return UserFactory(viewer=True)


@pytest.fixture
def auth_client(api_client, admin_user):
    refresh = RefreshToken.for_user(admin_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.mark.django_db
class TestDeviceRegistration:
    def test_register_device_for_authenticated_admin(self, auth_client, admin_user):
        response = auth_client.post(
            "/api/notifications/devices/",
            {"fcm_token": "token-1", "platform": "android"},
        )

        assert response.status_code == status.HTTP_201_CREATED
        device = Device.objects.get(fcm_token="token-1")
        assert device.user == admin_user
        assert device.platform == Device.Platform.ANDROID
        assert device.is_active is True

    def test_register_device_updates_existing_token_owner(self, api_client, admin_user, reception_user):
        Device.objects.create(user=admin_user, fcm_token="shared-token", platform=Device.Platform.ANDROID)
        refresh = RefreshToken.for_user(reception_user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")

        response = api_client.post(
            "/api/notifications/devices/",
            {"fcm_token": "shared-token", "platform": "android"},
        )

        assert response.status_code == status.HTTP_200_OK
        device = Device.objects.get(fcm_token="shared-token")
        assert device.user == reception_user

    def test_register_device_requires_authentication(self, api_client):
        response = api_client.post(
            "/api/notifications/devices/",
            {"fcm_token": "token-2", "platform": "android"},
        )

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestAdminPushTask:
    @patch("apps.notifications.services.FCMService.send_push")
    def test_send_admin_push_notification_targets_only_admin_roles(self, mock_send_push):
        super_admin = UserFactory(role=User.Role.SUPER_ADMIN)
        reception = UserFactory(role=User.Role.RECEPTION)
        academy_manager = UserFactory(role=User.Role.ACADEMY_MANAGER)
        viewer = UserFactory(role=User.Role.VIEWER)

        Device.objects.create(user=super_admin, fcm_token="admin-token", platform=Device.Platform.ANDROID)
        Device.objects.create(user=reception, fcm_token="reception-token", platform=Device.Platform.ANDROID)
        Device.objects.create(user=academy_manager, fcm_token="manager-token", platform=Device.Platform.ANDROID)
        Device.objects.create(user=viewer, fcm_token="viewer-token", platform=Device.Platform.ANDROID)

        mock_send_push.return_value = 3

        result = send_admin_push_notification(
            title="اشتراك جديد بانتظار الموافقة",
            body="طلب جديد",
            notification_type="new_subscription",
            entity_id=77,
        )

        mock_send_push.assert_called_once()
        args, kwargs = mock_send_push.call_args
        assert set(args[0]) == {"admin-token", "reception-token", "manager-token"}
        assert args[1] == "اشتراك جديد بانتظار الموافقة"
        assert args[2] == "طلب جديد"
        assert kwargs["data"] == {"type": "new_subscription", "id": "77"}
        assert result == "Admin push sent to 3/3 devices"

    @patch("apps.notifications.services.FCMService.send_push")
    def test_send_admin_push_notification_handles_missing_devices(self, mock_send_push):
        result = send_admin_push_notification(
            title="تسجيل لاعب جديد",
            body="لا يوجد أجهزة",
            notification_type="new_registration",
        )

        mock_send_push.assert_not_called()
        assert result == "No admin devices registered"
