
from django.db import models
from django.utils import timezone


class Notification(models.Model):
    athlete = models.ForeignKey(
        "athletes.Athlete", on_delete=models.CASCADE, related_name="notifications", null=True, blank=True, db_index=True
    )
    title = models.CharField(max_length=200)
    body = models.TextField()
    is_read = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title

    def send_whatsapp(self, template_name: str = "notification_alert"):
        from .services import WhatsAppService

        success, result = WhatsAppService.send_template(
            self.athlete.phone, template_name, [self.athlete.full_name, self.title, self.body]
        )
        msg = WhatsAppMessage.objects.create(
            athlete=self.athlete,
            notification=self,
            template_name=template_name,
            message_body=f"{self.title}: {self.body}",
            recipient_phone=self.athlete.phone,
            status=WhatsAppMessage.Status.SENT if success else WhatsAppMessage.Status.FAILED,
            whatsapp_message_id=result if success else "",
            error_message="" if success else result,
            sent_at=timezone.now() if success else None,
        )
        return msg


class Announcement(models.Model):
    title = models.CharField(max_length=200)
    body = models.TextField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title


class WhatsAppMessage(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        SENT = "sent", "Sent"
        FAILED = "failed", "Failed"

    athlete = models.ForeignKey(
        "athletes.Athlete", on_delete=models.CASCADE, related_name="whatsapp_messages"
    )
    notification = models.ForeignKey(
        Notification, on_delete=models.SET_NULL, null=True, blank=True, related_name="whatsapp_messages"
    )
    template_name = models.CharField(max_length=100, blank=True)
    message_body = models.TextField()
    recipient_phone = models.CharField(max_length=20)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    whatsapp_message_id = models.CharField(max_length=100, blank=True)
    error_message = models.TextField(blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "WhatsApp Message"
        verbose_name_plural = "WhatsApp Messages"

    def __str__(self):
        return f"{self.athlete} - {self.get_status_display()}"


class Device(models.Model):
    class Platform(models.TextChoices):
        ANDROID = "android", "Android"
        IOS = "ios", "iOS"

    athlete = models.ForeignKey(
        "athletes.Athlete", on_delete=models.CASCADE, related_name="devices"
    )
    fcm_token = models.TextField(unique=True)
    platform = models.CharField(max_length=10, choices=Platform.choices, default=Platform.ANDROID)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Device"
        verbose_name_plural = "Devices"

    def __str__(self):
        return f"{self.athlete.full_name} ({self.platform})"
