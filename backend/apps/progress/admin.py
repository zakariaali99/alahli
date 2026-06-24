from django.contrib import admin

from .models import Achievement, DailyStat, WeeklyProgress

admin.site.register(WeeklyProgress)
admin.site.register(DailyStat)
admin.site.register(Achievement)
