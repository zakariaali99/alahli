from django.contrib import admin

from .models import SubscriptionPackage


@admin.register(SubscriptionPackage)
class SubscriptionPackageAdmin(admin.ModelAdmin):
    list_display = ["name", "price", "duration_value", "duration_type", "tag", "max_athletes", "order", "is_active"]
    list_editable = ["order", "is_active", "tag"]
    list_filter = ["tag", "is_active", "duration_type"]
    search_fields = ["name"]
