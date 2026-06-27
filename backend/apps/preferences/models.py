from django.db import models


class UserPreference(models.Model):
    class Language(models.TextChoices):
        ARABIC = "ar", "العربية"
        ENGLISH = "en", "English"

    class Theme(models.TextChoices):
        LIGHT = "light", "Light"
        DARK = "dark", "Dark"
        SYSTEM = "system", "System"

    user = models.OneToOneField(
        "accounts.User", on_delete=models.CASCADE, related_name="preferences"
    )
    notifications_enabled = models.BooleanField(default=True)
    sms_enabled = models.BooleanField(default=True)
    email_enabled = models.BooleanField(default=True)
    language = models.CharField(max_length=2, choices=Language.choices, default=Language.ARABIC)
    theme = models.CharField(max_length=10, choices=Theme.choices, default=Theme.LIGHT)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "User Preference"
        verbose_name_plural = "User Preferences"

    def __str__(self):
        return f"Preferences for {self.user.full_name_ar}"
