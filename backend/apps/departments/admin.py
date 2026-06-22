from django.contrib import admin

from .models import Department


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ["name_ar", "name", "color", "is_active"]
    list_editable = ["is_active"]
