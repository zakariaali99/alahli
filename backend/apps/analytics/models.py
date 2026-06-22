from django.db import models


class DashboardStats(models.Model):
    total_athletes = models.IntegerField(default=0)
    active_memberships = models.IntegerField(default=0)
    expired_memberships = models.IntegerField(default=0)
    expiring_soon = models.IntegerField(default=0)
    new_this_month = models.IntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Dashboard stats"
