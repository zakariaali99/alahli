from django.contrib import admin

from .models import DashboardStats


@admin.register(DashboardStats)
class DashboardStatsAdmin(admin.ModelAdmin):
    list_display = ["total_athletes", "active_memberships", "expired_memberships", "expiring_soon", "updated_at"]
