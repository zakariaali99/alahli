from django.contrib.auth.models import AbstractUser
from django.core.validators import FileExtensionValidator
from django.db import models

from .managers import UserManager


class User(AbstractUser):
    objects = UserManager()
    class Role(models.TextChoices):
        SUPER_ADMIN = "super_admin", "Super Admin"
        RECEPTION = "reception", "Reception Staff"
        ACADEMY_MANAGER = "academy_manager", "Academy Manager"
        TRAINER = "trainer", "Trainer"
        ATHLETE = "athlete", "Athlete"
        PARENT = "parent", "Parent"
        VIEWER = "viewer", "Viewer"

    username = None
    phone = models.CharField(max_length=20, unique=True)
    first_name_ar = models.CharField(max_length=50)
    last_name_ar = models.CharField(max_length=50)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.VIEWER)
    athlete = models.OneToOneField(
        "athletes.Athlete", on_delete=models.SET_NULL, null=True, blank=True,
        related_name="user_account",
    )
    academy = models.ForeignKey(
        "departments.Department", on_delete=models.SET_NULL, null=True, blank=True,
        related_name="managers"
    )
    is_active = models.BooleanField(default=True)
    photo = models.ImageField(
        upload_to="users/", blank=True, null=True,
        validators=[FileExtensionValidator(allowed_extensions=["jpg", "jpeg", "png", "webp"])],
    )

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS = ["first_name_ar", "last_name_ar"]

    class Meta:
        verbose_name = "User"
        verbose_name_plural = "Users"

    @property
    def full_name_ar(self):
        return f"{self.first_name_ar} {self.last_name_ar}".strip()

    def __str__(self):
        return f"{self.full_name_ar} ({self.phone})"
