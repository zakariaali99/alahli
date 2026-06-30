from django.db import models


class SubscriptionPackage(models.Model):
    class DurationType(models.TextChoices):
        WEEKS = "weeks", "Weeks"
        MONTHS = "months", "Months"

    class Tag(models.TextChoices):
        DISCOUNT = "discount", "Discount"
        SPECIAL = "special", "Special"
        NORMAL = "normal", "Normal"

    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    duration_type = models.CharField(max_length=10, choices=DurationType.choices, default=DurationType.MONTHS)
    duration_value = models.PositiveIntegerField(default=1, help_text="Number of weeks or months")
    max_athletes = models.PositiveIntegerField(default=1, help_text="Max athletes allowed for this package")
    tag = models.CharField(max_length=10, choices=Tag.choices, default=Tag.NORMAL, db_index=True)
    features = models.JSONField(default=list, blank=True)
    icon_name = models.CharField(max_length=100, blank=True, help_text="Icon identifier for frontend")
    color_class = models.CharField(max_length=100, blank=True, help_text="Tailwind or CSS class for styling")
    department = models.ForeignKey(
        "departments.Department", on_delete=models.CASCADE,
        null=True, blank=True, related_name="packages",
        help_text="Academy this package belongs to. Null = available to all academies.",
    )
    is_active = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order"]
        verbose_name = "Subscription Package"
        verbose_name_plural = "Subscription Packages"

    def __str__(self):
        return f"{self.name} - {self.price} LYD"
