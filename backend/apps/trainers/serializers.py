from rest_framework import serializers

from .models import Trainer, TrainerClass


class TrainerClassSerializer(serializers.ModelSerializer):
    price_display = serializers.SerializerMethodField()

    class Meta:
        model = TrainerClass
        fields = [
            "id", "title", "intensity", "description",
            "price", "price_display", "currency", "duration_minutes", "image_url",
        ]

    def get_price_display(self, obj):
        return f"{obj.price} د.ل"


class TrainerSerializer(serializers.ModelSerializer):
    classes = TrainerClassSerializer(many=True, read_only=True)

    class Meta:
        model = Trainer
        fields = [
            "id", "full_name_ar", "initials", "role", "bio",
            "rating", "reviews_count", "experience_years",
            "profile_image", "classes",
        ]
