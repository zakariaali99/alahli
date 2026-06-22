from rest_framework import serializers

from .models import Athlete


class AthleteListSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source="department.name_ar", read_only=True)

    class Meta:
        model = Athlete
        fields = [
            "id", "membership_number", "full_name", "phone",
            "gender", "department", "department_name",
            "photo", "is_active", "created_at",
        ]


class AthleteDetailSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source="department.name_ar", read_only=True)

    class Meta:
        model = Athlete
        fields = "__all__"
        read_only_fields = ["membership_number", "qr_code"]

    def create(self, validated_data):
        return Athlete.objects.create(**validated_data)
