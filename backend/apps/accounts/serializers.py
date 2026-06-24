from rest_framework import serializers

from apps.athletes.serializers import AthleteDetailSerializer

from .models import User


class UserSerializer(serializers.ModelSerializer):
    athlete_detail = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "phone", "first_name_ar", "last_name_ar", "full_name_ar", "role", "is_active", "athlete_detail"]
        read_only_fields = ["id"]

    def get_athlete_detail(self, obj):
        if hasattr(obj, "athlete") and obj.athlete is not None:
            return AthleteDetailSerializer(obj.athlete).data
        return None


class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField()
    password = serializers.CharField()


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, min_length=8)
