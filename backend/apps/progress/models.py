from django.db import models


class WeeklyProgress(models.Model):
    user = models.ForeignKey(
        "accounts.User", on_delete=models.CASCADE, related_name="weekly_progress", db_index=True
    )
    week_start = models.DateField()
    sessions_count = models.PositiveIntegerField(default=0)
    active_minutes = models.PositiveIntegerField(default=0)
    goal_progress = models.FloatField(default=0.0)
    goal_target = models.PositiveIntegerField(default=5)

    class Meta:
        ordering = ["-week_start"]
        unique_together = ["user", "week_start"]

    def __str__(self):
        return f"Week {self.week_start} - {self.sessions_count} sessions"


class DailyStat(models.Model):
    weekly_progress = models.ForeignKey(
        WeeklyProgress, on_delete=models.CASCADE, related_name="daily_stats"
    )
    day_abbr = models.CharField(max_length=2)
    day_full = models.CharField(max_length=20)
    value = models.FloatField(default=0.0)
    hours = models.FloatField(default=0.0)

    class Meta:
        ordering = ["weekly_progress", "id"]

    def __str__(self):
        return f"{self.day_full}: {self.value}"


class Achievement(models.Model):
    class Status(models.TextChoices):
        LOCKED = "locked", "Locked"
        UNLOCKED = "unlocked", "Unlocked"
        COMPLETED = "completed", "Completed"

    user = models.ForeignKey(
        "accounts.User", on_delete=models.CASCADE, related_name="achievements"
    )
    icon = models.CharField(max_length=50)
    title = models.CharField(max_length=200)
    subtitle = models.CharField(max_length=200, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.LOCKED)
    unlocked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["id"]

    def __str__(self):
        return self.title
