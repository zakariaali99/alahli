from django.contrib import admin

from .models import Booking, Exercise, ExerciseEquipment, ExerciseMovement, SessionCategory, WorkoutSession

admin.site.register(SessionCategory)
admin.site.register(WorkoutSession)
admin.site.register(Exercise)
admin.site.register(ExerciseMovement)
admin.site.register(ExerciseEquipment)
admin.site.register(Booking)
