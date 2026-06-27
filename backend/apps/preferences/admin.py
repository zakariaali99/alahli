from django.contrib import admin

from .models import UserPreference


@admin.register(UserPreference)
class UserPreferenceAdmin(admin.ModelAdmin):
    list_display = ["user", "notifications_enabled", "language", "theme"]
    search_fields = ["user__phone"]
