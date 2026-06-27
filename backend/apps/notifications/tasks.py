import logging

from celery import shared_task
from django.utils import timezone

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def send_whatsapp_message(self, athlete_id: int, title: str, body: str, template_name: str = "notification_alert"):
    from apps.athletes.models import Athlete
    from apps.notifications.models import Notification, WhatsAppMessage
    from apps.notifications.services import WhatsAppService

    try:
        athlete = Athlete.objects.get(id=athlete_id)
    except Athlete.DoesNotExist:
        return f"Athlete {athlete_id} not found"

    user_account = getattr(athlete, "user_account", None)
    if user_account:
        pref = getattr(user_account, "preferences", None)
        if pref and not pref.sms_enabled:
            return f"Skipped {athlete.full_name} — sms disabled"

    if not athlete.phone:
        return f"No phone for {athlete.full_name}"

    success, result = WhatsAppService.send_template(
        athlete.phone, template_name, [athlete.full_name, title, body]
    )

    notification = Notification.objects.create(
        athlete=athlete, title=title, body=body
    )

    WhatsAppMessage.objects.create(
        athlete=athlete,
        notification=notification,
        template_name=template_name,
        message_body=f"{title}: {body}",
        recipient_phone=athlete.phone,
        status=WhatsAppMessage.Status.SENT if success else WhatsAppMessage.Status.FAILED,
        whatsapp_message_id=result if success else "",
        error_message="" if success else result,
        sent_at=timezone.now() if success else None,
    )

    if success:
        logger.info("WhatsApp sent to %s (%s): %s", athlete.full_name, athlete.phone, result)
        return f"Sent to {athlete.full_name}"
    else:
        logger.error("WhatsApp failed for %s (%s): %s", athlete.full_name, athlete.phone, result)
        raise self.retry(exc=Exception(result))


@shared_task
def send_push_notification(notification_id: int):
    from apps.notifications.models import Device, Notification
    from apps.notifications.services import FCMService

    try:
        notification = Notification.objects.get(id=notification_id)
    except Notification.DoesNotExist:
        return f"Notification {notification_id} not found"

    athlete = notification.athlete
    if not athlete:
        return "No athlete linked"

    tokens = list(
        Device.objects.filter(athlete=athlete, is_active=True)
        .values_list("fcm_token", flat=True)
    )

    if not tokens:
        return f"No devices for {athlete.full_name}"

    count = FCMService.send_push(
        tokens,
        notification.title,
        notification.body,
        data={"notification_id": str(notification.id), "type": "notification"},
    )

    logger.info("Push sent to %d/%d devices for %s", count, len(tokens), athlete.full_name)
    return f"Sent to {count}/{len(tokens)} devices"
