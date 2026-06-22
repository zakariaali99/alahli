from django.contrib import admin

from .models import Athlete


@admin.register(Athlete)
class AthleteAdmin(admin.ModelAdmin):
    list_display = ["membership_number", "full_name", "phone", "department", "is_active"]
    list_filter = ["department", "gender", "is_active"]
    search_fields = ["full_name", "membership_number", "phone"]
