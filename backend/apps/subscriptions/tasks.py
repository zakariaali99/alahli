from datetime import date, timedelta

from celery import shared_task
from django.conf import settings

from apps.notifications.models import Notification

from .models import Subscription


@shared_task
def expire_memberships():
    today = date.today()
    expired = Subscription.objects.filter(
        status=Subscription.Status.ACTIVE, end_date__lt=today
    )
    expired_ids = list(expired.values_list("id", flat=True))
    count = expired.update(status=Subscription.Status.EXPIRED)

    if count > 0:
        from apps.notifications.services import send_admin_push_sync

        send_admin_push_sync(
            title="انتهاء اشتراكات",
            body=f"انتهى {count} اشتراك اليوم. يرجى مراجعة قائمة الاشتراكات المنتهية.",
            notification_type="subscription_expired",
        )

    return f"Expired {count} memberships"


@shared_task
def alert_expiring_soon():
    today = date.today()
    week_later = today + timedelta(days=7)
    expiring = Subscription.objects.filter(
        status=Subscription.Status.ACTIVE,
        end_date__gte=today,
        end_date__lte=week_later,
    )

    count = 0
    whatsapp_count = 0
    for sub in expiring:
        Notification.objects.create(
            athlete=sub.athlete,
            title="Membership expiring soon",
            body=f"Your membership will expire on {sub.end_date}",
        )
        count += 1

        if getattr(settings, "WHATSAPP_AUTO_SEND_ENABLED", False):
            from apps.notifications.tasks import send_whatsapp_message

            send_whatsapp_message.delay(
                sub.athlete_id,
                "Membership expiring soon",
                f"Your membership will expire on {sub.end_date}",
                "membership_expiring",
            )
            whatsapp_count += 1

    parts = [f"Created {count} expiry alerts"]
    if whatsapp_count:
        parts.append(f"Queued {whatsapp_count} WhatsApp messages")
    return " | ".join(parts)
