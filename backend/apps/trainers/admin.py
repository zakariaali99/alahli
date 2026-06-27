from django.contrib import admin

from .models import Trainer, TrainerClass, TrainerReview

admin.site.register(Trainer)
admin.site.register(TrainerClass)
admin.site.register(TrainerReview)
