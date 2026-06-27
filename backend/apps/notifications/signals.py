import logging

from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import Notification
from .tasks import send_push_notification

logger = logging.getLogger(__name__)


@receiver(post_save, sender=Notification, dispatch_uid="notification_push")
def notify_push_on_create(sender, instance, created, **kwargs):
    if created and instance.athlete_id:
        try:
            send_push_notification.delay(instance.id)
        except Exception as e:
            logger.warning("Failed to queue push notification: %s", e)
