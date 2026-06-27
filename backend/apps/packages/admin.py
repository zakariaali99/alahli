from django.contrib import admin

from .models import SubscriptionPackage


@admin.register(SubscriptionPackage)
class SubscriptionPackageAdmin(admin.ModelAdmin):
    list_display = ["name", "price", "duration_days", "order", "is_active"]
    list_editable = ["order", "is_active"]
    search_fields = ["name"]
