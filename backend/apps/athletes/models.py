import io
import uuid

import qrcode
from django.core.files.base import ContentFile
from django.core.validators import FileExtensionValidator
from django.db import models


def generate_membership_number():
    prefix = "ALA"
    unique = uuid.uuid4().hex[:8].upper()
    return f"{prefix}-{unique}"


class Athlete(models.Model):
    class Gender(models.TextChoices):
        MALE = "male", "Male"
        FEMALE = "female", "Female"

    membership_number = models.CharField(
        max_length=20, unique=True, default=generate_membership_number, editable=False
    )
    full_name = models.CharField(max_length=100, db_index=True)
    phone = models.CharField(max_length=20, unique=True, db_index=True)
    parent_phone = models.CharField(max_length=20, blank=True)
    birth_date = models.DateField()
    gender = models.CharField(max_length=10, choices=Gender.choices)
    department = models.ForeignKey(
        "departments.Department", on_delete=models.SET_NULL, null=True, related_name="athletes"
    )
    photo = models.ImageField(
        upload_to="athletes/",
        blank=True,
        null=True,
        validators=[FileExtensionValidator(allowed_extensions=["jpg", "jpeg", "png", "webp"])],
    )
    qr_code = models.ImageField(upload_to="qrcodes/", blank=True, null=True)
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.full_name} ({self.membership_number})"

    registration = models.OneToOneField(
        "athletes.RegistrationRequest", on_delete=models.SET_NULL, null=True, blank=True,
        related_name="athlete",
    )

    def save(self, *args, **kwargs):
        if not self.qr_code:
            self.generate_qr_code()
        super().save(*args, **kwargs)

    def generate_qr_code(self):
        qr = qrcode.QRCode(box_size=10, border=4)
        qr.add_data(self.membership_number)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        filename = f"qr_{self.membership_number}.png"
        self.qr_code.save(filename, ContentFile(buffer.getvalue()), save=False)


class RegistrationRequest(models.Model):
    class RoleChoice(models.TextChoices):
        ATHLETE = "athlete", "Athlete"
        PARENT = "parent", "Parent"

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    user = models.ForeignKey(
        "accounts.User", on_delete=models.CASCADE, related_name="registration_requests",
    )
    role_choice = models.CharField(max_length=10, choices=RoleChoice.choices)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True)
    reviewed_by = models.ForeignKey(
        "accounts.User", on_delete=models.SET_NULL, null=True, blank=True,
        related_name="reviewed_registrations",
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.full_name_ar} ({self.role_choice}) - {self.status}"


class ParentAthlete(models.Model):
    parent = models.ForeignKey(
        "accounts.User", on_delete=models.CASCADE, related_name="managed_athletes",
    )
    athlete = models.ForeignKey(Athlete, on_delete=models.CASCADE, related_name="parents")
    relationship = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        unique_together = [("parent", "athlete")]

    def __str__(self):
        return f"{self.parent.full_name_ar} → {self.athlete.full_name}"
