from django.db import models


class SubscriptionPackage(models.Model):
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    duration_days = models.PositiveIntegerField()
    features = models.JSONField(default=list, blank=True)
    icon_name = models.CharField(max_length=100, blank=True, help_text="Icon identifier for frontend")
    color_class = models.CharField(max_length=100, blank=True, help_text="Tailwind or CSS class for styling")
    is_active = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order"]
        verbose_name = "Subscription Package"
        verbose_name_plural = "Subscription Packages"

    def __str__(self):
        return f"{self.name} - {self.price} LYD"
