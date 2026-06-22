from django.db import models


class Notification(models.Model):
    athlete = models.ForeignKey(
        "athletes.Athlete", on_delete=models.CASCADE, related_name="notifications", null=True, blank=True
    )
    title = models.CharField(max_length=200)
    body = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title
