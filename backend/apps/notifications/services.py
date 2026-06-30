import json
import logging
import re
import urllib.error
import urllib.request
from typing import Optional

from django.conf import settings

logger = logging.getLogger(__name__)


class WhatsAppService:
    BASE_URL = "https://graph.facebook.com/v22.0"

    @classmethod
    def _headers(cls) -> dict:
        return {
            "Authorization": f"Bearer {settings.WHATSAPP_ACCESS_TOKEN}",
            "Content-Type": "application/json",
        }

    @classmethod
    def normalize_phone(cls, phone: str) -> Optional[str]:
        digits = re.sub(r"\D", "", phone)

        if digits.startswith("218") and len(digits) >= 11:
            return "+" + digits
        if digits.startswith("09") and len(digits) == 10:
            return "+218" + digits[1:]
        if len(digits) == 9 and not digits.startswith("0"):
            return "+218" + digits
        if digits.startswith("00218"):
            return "+" + digits[2:]
        return None

    @classmethod
    def send_template(
        cls,
        to_phone: str,
        template_name: str,
        params: Optional[list] = None,
        lang: str = "en",
    ) -> tuple:
        phone = cls.normalize_phone(to_phone)
        if not phone:
            return False, f"Invalid phone number: {to_phone}"

        data = {
            "messaging_product": "whatsapp",
            "to": phone,
            "type": "template",
            "template": {
                "name": template_name,
                "language": {"code": lang},
            },
        }

        if params:
            data["template"]["components"] = [
                {
                    "type": "body",
                    "parameters": [{"type": "text", "text": p} for p in params],
                }
            ]

        return cls._post(data)

    @classmethod
    def send_text(
        cls, to_phone: str, message: str
    ) -> tuple:
        phone = cls.normalize_phone(to_phone)
        if not phone:
            return False, f"Invalid phone number: {to_phone}"

        data = {
            "messaging_product": "whatsapp",
            "to": phone,
            "type": "text",
            "text": {"preview_url": False, "body": message},
        }

        return cls._post(data)

    @classmethod
    def _post(cls, data: dict) -> tuple:
        url = f"{cls.BASE_URL}/{settings.WHATSAPP_PHONE_NUMBER_ID}/messages"
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        req = urllib.request.Request(
            url, data=body, headers=cls._headers(), method="POST"
        )

        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                result = json.loads(resp.read())
                msg_id = result.get("messages", [{}])[0].get("id", "")
                return True, msg_id
        except urllib.error.HTTPError as e:
            error_body = e.read().decode()
            logger.error("WhatsApp API error %s: %s", e.code, error_body)
            return False, f"HTTP {e.code}: {error_body}"
        except urllib.error.URLError as e:
            logger.error("WhatsApp API request failed: %s", e.reason)
            return False, str(e.reason)


def send_admin_push_sync(title: str, body: str, notification_type: str, entity_id: int = None) -> int:
    from apps.accounts.models import User
    from apps.notifications.models import Device

    admin_roles = [User.Role.SUPER_ADMIN, User.Role.RECEPTION, "academy_manager"]
    tokens = list(
        Device.objects.filter(user__role__in=admin_roles, is_active=True)
        .values_list("fcm_token", flat=True)
    )

    if not tokens:
        logger.info("No admin devices registered for push notification")
        return 0

    data = {"type": notification_type}
    if entity_id:
        data["id"] = str(entity_id)

    count = FCMService.send_push(tokens, title, body, data=data)
    logger.info("Admin push sent to %d/%d devices: %s", count, len(tokens), title)
    return count


class FCMService:
    @staticmethod
    def send_push(device_tokens: list, title: str, body: str, data: Optional[dict] = None) -> int:
        try:
            import firebase_admin
            from firebase_admin import credentials, messaging
        except ImportError:
            logger.warning("firebase-admin not installed, skipping push")
            return 0

        try:
            firebase_admin.get_app()
        except ValueError:
            cred_path = getattr(settings, "FCM_CREDENTIALS_PATH", None)
            if not cred_path:
                logger.warning("FCM_CREDENTIALS_PATH not set, skipping push")
                return 0
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)

        message = messaging.MulticastMessage(
            tokens=device_tokens,
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
        )

        try:
            response = messaging.send_each_for_multicast(message)
            success_count = response.success_count
            if response.failure_count > 0:
                logger.warning("FCM partial failure: %d/%d failed", response.failure_count, len(device_tokens))
            return success_count
        except Exception as e:
            logger.error("FCM send failed: %s", e)
            return 0
