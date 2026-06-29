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
    bank_account_number = models.CharField(max_length=50, blank=True, default="")
    iban = models.CharField(max_length=34, blank=True, default="")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name_ar


class Sport(models.Model):
    name = models.CharField(max_length=100)
    name_ar = models.CharField(max_length=100)
    department = models.ForeignKey(Department, on_delete=models.CASCADE, related_name="sports")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name_ar


WEEKDAY_CHOICES = [
    ("saturday", "السبت"),
    ("sunday", "الأحد"),
    ("monday", "الإثنين"),
    ("tuesday", "الثلاثاء"),
    ("wednesday", "الأربعاء"),
    ("thursday", "الخميس"),
    ("friday", "الجمعة"),
]


class Group(models.Model):
    name = models.CharField(max_length=100)
    name_ar = models.CharField(max_length=100)
    sport = models.ForeignKey(Sport, on_delete=models.CASCADE, related_name="groups")
    coach = models.ForeignKey(
        "accounts.User", on_delete=models.SET_NULL, null=True, blank=True,
        limit_choices_to={"role": "trainer"}, related_name="coached_groups",
    )
    days = models.JSONField(default=list, blank=True)
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["sport__name", "name"]

    def __str__(self):
        return self.name_ar
