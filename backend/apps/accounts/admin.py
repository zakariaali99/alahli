from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ["phone", "full_name_ar", "role", "is_active"]
    list_filter = ["role", "is_active"]
    search_fields = ["phone", "first_name_ar", "last_name_ar"]
    ordering = ["-date_joined"]

    fieldsets = (
        (None, {"fields": ("phone", "password")}),
        ("Personal info", {"fields": ("first_name_ar", "last_name_ar", "email")}),
        ("Permissions", {"fields": ("role", "is_active", "is_staff", "is_superuser")}),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )

    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("phone", "first_name_ar", "last_name_ar", "password1", "password2", "role"),
        }),
    )
