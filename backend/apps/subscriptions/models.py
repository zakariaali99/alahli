from django.db import models

from apps.athletes.models import Athlete


class Subscription(models.Model):
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        EXPIRED = "expired", "Expired"
        PENDING = "pending", "Pending"
        REJECTED = "rejected", "Rejected"

    class PaymentMethod(models.TextChoices):
        CASH = "cash", "Cash"
        BANK_TRANSFER = "bank_transfer", "Bank Transfer"

    athlete = models.ForeignKey(
        Athlete, on_delete=models.CASCADE, related_name="subscriptions"
    )
    package_name = models.CharField(max_length=100, default="الباقة الأساسية")
    start_date = models.DateField()
    end_date = models.DateField(db_index=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(
        max_length=20, choices=PaymentMethod.choices, default=PaymentMethod.CASH,
    )
    invoice_pdf = models.FileField(
        upload_to="invoices/", null=True, blank=True,
    )
    group = models.ForeignKey(
        "departments.Group", on_delete=models.SET_NULL, null=True, blank=True,
        related_name="subscriptions",
    )
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True)
    approved_by = models.ForeignKey(
        "accounts.User", on_delete=models.SET_NULL, null=True, blank=True,
        related_name="approved_subscriptions",
    )
    approved_at = models.DateTimeField(null=True, blank=True)
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


class AttendanceLog(models.Model):
    athlete = models.ForeignKey(
        Athlete, on_delete=models.CASCADE, related_name="attendance_logs", db_index=True
    )
    subscription = models.ForeignKey(
        Subscription, on_delete=models.CASCADE, related_name="attendance_logs", null=True, blank=True
    )
    checked_in_at = models.DateTimeField(auto_now_add=True)
    verified_by = models.ForeignKey(
        "accounts.User", on_delete=models.SET_NULL, null=True, blank=True
    )

    class Meta:
        ordering = ["-checked_in_at"]
        verbose_name = "Attendance Log"
        verbose_name_plural = "Attendance Logs"

    def __str__(self):
        return f"{self.athlete.full_name} - {self.checked_in_at}"
