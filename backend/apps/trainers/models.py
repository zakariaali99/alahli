from django.db import models


class Trainer(models.Model):
    full_name_ar = models.CharField(max_length=100)
    initials = models.CharField(max_length=10)
    role = models.CharField(max_length=200)
    bio = models.TextField(blank=True)
    rating = models.DecimalField(max_digits=3, decimal_places=1, default=0.0)
    reviews_count = models.PositiveIntegerField(default=0)
    experience_years = models.PositiveIntegerField(default=0)
    profile_image = models.URLField(blank=True)

    class Meta:
        ordering = ["full_name_ar"]

    def __str__(self):
        return self.full_name_ar


class TrainerClass(models.Model):
    trainer = models.ForeignKey(
        Trainer, on_delete=models.CASCADE, related_name="classes"
    )
    title = models.CharField(max_length=200)
    intensity = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default="LYD")
    duration_minutes = models.PositiveIntegerField()
    image_url = models.URLField(blank=True)

    class Meta:
        verbose_name_plural = "Trainer classes"
        ordering = ["title"]

    def __str__(self):
        return self.title
