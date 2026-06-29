from rest_framework import serializers

from .models import Department, Group, Sport


class DepartmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = "__all__"


class SportSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source="department.name_ar", read_only=True)

    class Meta:
        model = Sport
        fields = "__all__"
        read_only_fields = ["created_at"]


class GroupSerializer(serializers.ModelSerializer):
    sport_name = serializers.CharField(source="sport.name_ar", read_only=True)
    coach_name = serializers.CharField(source="coach.full_name_ar", read_only=True, default="")

    class Meta:
        model = Group
        fields = "__all__"
        read_only_fields = ["created_at"]
