from django.contrib import admin

from .models import Athlete, ParentAthlete, RegistrationRequest


@admin.register(Athlete)
class AthleteAdmin(admin.ModelAdmin):
    list_display = ["membership_number", "full_name", "phone", "department", "is_active"]
    list_filter = ["department", "gender", "is_active"]
    search_fields = ["full_name", "membership_number", "phone"]


@admin.register(RegistrationRequest)
class RegistrationRequestAdmin(admin.ModelAdmin):
    list_display = ["user", "role_choice", "status", "reviewed_by", "reviewed_at", "created_at"]
    list_filter = ["status", "role_choice"]
    search_fields = ["user__first_name_ar", "user__last_name_ar", "user__phone"]


@admin.register(ParentAthlete)
class ParentAthleteAdmin(admin.ModelAdmin):
    list_display = ["parent", "athlete", "relationship", "created_at"]
    search_fields = ["parent__first_name_ar", "athlete__full_name"]
