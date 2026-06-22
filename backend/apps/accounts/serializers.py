from rest_framework import serializers

from .models import User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "phone", "first_name_ar", "last_name_ar", "full_name_ar", "role", "is_active"]
        read_only_fields = ["id"]


class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField()
    password = serializers.CharField()


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, min_length=8)
