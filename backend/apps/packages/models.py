from django.db import models


class SubscriptionPackage(models.Model):
    class DurationType(models.TextChoices):
        DAYS = "days", "Days"
        WEEKS = "weeks", "Weeks"
        MONTHS = "months", "Months"

    class PackageType(models.TextChoices):
        MONTHLY = "monthly", "Monthly"
        MULTI_MONTH = "multi_month", "Multi-Month"
        SINGLE_SESSION = "single_session", "Single Session (حصة)"

    class Tag(models.TextChoices):
        DISCOUNT = "discount", "Discount"
        SPECIAL = "special", "Special"
        NORMAL = "normal", "Normal"

    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, help_text="Base/New price for backward compatibility")
    new_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, help_text="First-time subscription price")
    renewal_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, help_text="Renewal subscription price")
    package_type = models.CharField(max_length=20, choices=PackageType.choices, default=PackageType.MONTHLY)
    duration_type = models.CharField(max_length=10, choices=DurationType.choices, default=DurationType.MONTHS)
    duration_value = models.PositiveIntegerField(default=1, help_text="Number of days, weeks or months")
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

    def save(self, *args, **kwargs):
        if not self.new_price and self.price:
            self.new_price = self.price
        elif self.new_price and not self.price:
            self.price = self.new_price
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} - New: {self.new_price} LYD / Renew: {self.renewal_price} LYD"
