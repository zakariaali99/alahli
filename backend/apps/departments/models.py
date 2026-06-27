from django.core.validators import FileExtensionValidator, RegexValidator
from django.db import models


class Department(models.Model):
    name = models.CharField(max_length=100, unique=True)
    name_ar = models.CharField(max_length=100, unique=True)
    color = models.CharField(
        max_length=7, default="#1487D4",
        validators=[RegexValidator(r"^#[0-9A-Fa-f]{6}$", "Enter a valid hex color")],
    )
    logo = models.ImageField(upload_to="departments/", blank=True, null=True,
                              validators=[FileExtensionValidator(["jpg", "jpeg", "png", "webp"])])
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name_ar
