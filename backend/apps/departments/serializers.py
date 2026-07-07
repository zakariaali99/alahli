from rest_framework import serializers

from .models import Department, Group, Sport


MAX_DEPARTMENTS = 3


class DepartmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = "__all__"

    def validate(self, attrs):
        if self.instance is None and Department.objects.count() >= MAX_DEPARTMENTS:
            raise serializers.ValidationError(
                f"لا يمكن إضافة أكثر من {MAX_DEPARTMENTS} أكاديميات."
            )
        return attrs


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
