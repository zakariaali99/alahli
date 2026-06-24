from rest_framework import serializers

from .models import Booking, Exercise, ExerciseEquipment, ExerciseMovement, SessionCategory, WorkoutSession


class SessionCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SessionCategory
        fields = ["id", "slug", "display_ar"]


class ExerciseMovementSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExerciseMovement
        fields = ["id", "name", "sets", "reps", "image_url", "order"]


class ExerciseEquipmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExerciseEquipment
        fields = ["id", "name"]


class ExerciseSerializer(serializers.ModelSerializer):
    movements = ExerciseMovementSerializer(many=True, read_only=True)
    equipment = ExerciseEquipmentSerializer(many=True, read_only=True)

    class Meta:
        model = Exercise
        fields = [
            "id", "title", "description", "image_url", "calories",
            "duration_minutes", "difficulty", "movements", "equipment",
        ]


class WorkoutSessionSerializer(serializers.ModelSerializer):
    category_display = serializers.CharField(source="category.display_ar", read_only=True)
    trainer_name = serializers.CharField(source="trainer.full_name_ar", read_only=True)
    trainer_initials = serializers.CharField(source="trainer.initials", read_only=True)

    class Meta:
        model = WorkoutSession
        fields = [
            "id", "name", "category", "category_display", "date", "time",
            "duration_minutes", "location", "trainer", "trainer_name",
            "trainer_initials", "is_completed", "created_at",
        ]


class BookingSerializer(serializers.ModelSerializer):
    session_name = serializers.CharField(source="workout_session.name", read_only=True)
    coach_name = serializers.CharField(source="workout_session.trainer.full_name_ar", read_only=True)

    class Meta:
        model = Booking
        fields = [
            "id", "workout_session", "session_name", "coach_name",
            "date", "time", "status", "confirmed_at",
        ]
        read_only_fields = ["status", "confirmed_at"]
