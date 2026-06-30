from datetime import date, timedelta

from django.conf import settings
from django.core.management.base import BaseCommand

from apps.notifications.models import Notification

from ...models import Subscription


class Command(BaseCommand):
    help = "Expire past memberships and create alerts for expiring ones"

    def handle(self, *args, **options):
        today = date.today()
        week_later = today + timedelta(days=7)

        # ── Expire past memberships ──
        expired = Subscription.objects.filter(
            status=Subscription.Status.ACTIVE, end_date__lt=today
        )
        expired_count = expired.count()
        if expired_count > 0:
            expired_ids = list(expired.values_list("id", flat=True))
            updated = Subscription.objects.filter(id__in=expired_ids).update(
                status=Subscription.Status.EXPIRED
            )
            self.stdout.write(f"Expired {updated} past memberships")
        else:
            self.stdout.write("No memberships to expire")

        if expired_count > 0:
            from apps.notifications.services import send_admin_push_sync

            send_admin_push_sync(
                title="انتهاء اشتراكات",
                body=f"انتهى {expired_count} اشتراك اليوم. يرجى مراجعة قائمة الاشتراكات المنتهية.",
                notification_type="subscription_expired",
            )

        # ── Alert for memberships expiring within 7 days ──
        expiring = Subscription.objects.filter(
            status=Subscription.Status.ACTIVE,
            end_date__gte=today,
            end_date__lte=week_later,
        )

        alert_count = 0
        whatsapp_count = 0
        for sub in expiring:
            Notification.objects.create(
                athlete=sub.athlete,
                title="Membership expiring soon",
                body=f"Your membership will expire on {sub.end_date}",
            )
            alert_count += 1

            if getattr(settings, "WHATSAPP_AUTO_SEND_ENABLED", False):
                from apps.notifications.tasks import send_whatsapp_message

                send_whatsapp_message.delay(
                    sub.athlete_id,
                    "Membership expiring soon",
                    f"Your membership will expire on {sub.end_date}",
                    "membership_expiring",
                )
                whatsapp_count += 1

        self.stdout.write(f"Created {alert_count} expiry alert notifications")
        if whatsapp_count:
            self.stdout.write(f"Queued {whatsapp_count} WhatsApp alerts")
