from django.contrib import admin

from .models import AttendanceLog, Renewal, Subscription


class RenewalInline(admin.TabularInline):
    model = Renewal
    extra = 0
    readonly_fields = ["renewal_date", "amount", "months"]


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ["athlete", "status", "start_date", "end_date", "amount"]
    list_filter = ["status"]
    search_fields = ["athlete__full_name", "athlete__membership_number"]
    inlines = [RenewalInline]


@admin.register(Renewal)
class RenewalAdmin(admin.ModelAdmin):
    list_display = ["subscription", "amount", "months", "renewal_date", "created_by"]


@admin.register(AttendanceLog)
class AttendanceLogAdmin(admin.ModelAdmin):
    list_display = ["athlete", "checked_in_at", "verified_by"]
    list_filter = ["checked_in_at"]
