from django.contrib import admin

from .models import Department, Group, Sport


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ["name_ar", "name", "color", "is_active"]
    list_editable = ["is_active"]


@admin.register(Sport)
class SportAdmin(admin.ModelAdmin):
    list_display = ["name_ar", "name", "department", "is_active"]
    list_filter = ["department", "is_active"]
    list_editable = ["is_active"]


@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = ["name_ar", "name", "sport", "coach", "start_time", "end_time", "is_active"]
    list_filter = ["sport__department", "sport", "is_active"]
    list_editable = ["is_active"]
