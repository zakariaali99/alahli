from django.db import models

from apps.trainers.models import Trainer


class SessionCategory(models.Model):
    slug = models.SlugField(unique=True)
    display_ar = models.CharField(max_length=100)

    class Meta:
        verbose_name_plural = "Session categories"

    def __str__(self):
        return self.display_ar


class WorkoutSession(models.Model):
    name = models.CharField(max_length=200)
    category = models.ForeignKey(
        SessionCategory, on_delete=models.SET_NULL, null=True, related_name="sessions"
    )
    date = models.DateField()
    time = models.TimeField()
    duration_minutes = models.PositiveIntegerField()
    location = models.CharField(max_length=200)
    trainer = models.ForeignKey(
        Trainer, on_delete=models.SET_NULL, null=True, related_name="sessions"
    )
    is_completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["date", "time"]

    def __str__(self):
        return f"{self.name} - {self.date}"


class Exercise(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    image_url = models.URLField(blank=True)
    calories = models.PositiveIntegerField(default=0)
    duration_minutes = models.PositiveIntegerField(default=30)
    difficulty = models.CharField(max_length=50, default="intermediate")

    class Meta:
        ordering = ["title"]

    def __str__(self):
        return self.title


class ExerciseMovement(models.Model):
    exercise = models.ForeignKey(
        Exercise, on_delete=models.CASCADE, related_name="movements"
    )
    name = models.CharField(max_length=200)
    sets = models.PositiveIntegerField()
    reps = models.PositiveIntegerField()
    image_url = models.URLField(blank=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["order"]

    def __str__(self):
        return self.name


class ExerciseEquipment(models.Model):
    exercise = models.ForeignKey(
        Exercise, on_delete=models.CASCADE, related_name="equipment"
    )
    name = models.CharField(max_length=200)

    def __str__(self):
        return self.name


class Booking(models.Model):
    class Status(models.TextChoices):
        CONFIRMED = "confirmed", "Confirmed"
        PENDING = "pending", "Pending"
        CANCELLED = "cancelled", "Cancelled"

    workout_session = models.ForeignKey(
        WorkoutSession, on_delete=models.CASCADE, related_name="bookings"
    )
    user = models.ForeignKey(
        "accounts.User", on_delete=models.CASCADE, related_name="bookings"
    )
    date = models.DateField()
    time = models.TimeField()
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    confirmed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-confirmed_at"]

    def __str__(self):
        return f"{self.workout_session.name} - {self.user}"
