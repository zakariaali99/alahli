import io
import uuid

import qrcode
from django.core.files.base import ContentFile
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
    full_name = models.CharField(max_length=100)
    phone = models.CharField(max_length=20)
    parent_phone = models.CharField(max_length=20, blank=True)
    birth_date = models.DateField()
    gender = models.CharField(max_length=10, choices=Gender.choices)
    department = models.ForeignKey(
        "departments.Department", on_delete=models.SET_NULL, null=True, related_name="athletes"
    )
    photo = models.ImageField(upload_to="athletes/", blank=True, null=True)
    qr_code = models.ImageField(upload_to="qrcodes/", blank=True, null=True)
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.full_name} ({self.membership_number})"

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
