from django.db import models

from apps.athletes.models import Athlete


class Subscription(models.Model):
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        EXPIRED = "expired", "Expired"
        PENDING = "pending", "Pending"

    athlete = models.ForeignKey(
        Athlete, on_delete=models.CASCADE, related_name="subscriptions"
    )
    package_name = models.CharField(max_length=100, default="الباقة الأساسية")
    start_date = models.DateField()
    end_date = models.DateField()
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.athlete.full_name} - {self.status}"


class Renewal(models.Model):
    subscription = models.ForeignKey(
        Subscription, on_delete=models.CASCADE, related_name="renewals"
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    months = models.IntegerField()
    renewal_date = models.DateField(auto_now_add=True)
    created_by = models.ForeignKey(
        "accounts.User", on_delete=models.SET_NULL, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Renewal: {self.subscription.athlete.full_name} ({self.months}m)"
