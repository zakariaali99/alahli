from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

from apps.athletes.serializers import AthleteDetailSerializer

from .models import User


class UserSerializer(serializers.ModelSerializer):
    athlete_detail = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "phone", "first_name_ar", "last_name_ar", "full_name_ar", "role", "is_active", "athlete_detail"]
        read_only_fields = ["id"]

    def get_athlete_detail(self, obj):
        athlete = getattr(obj, "athlete", None)
        if athlete is not None:
            return AthleteDetailSerializer(athlete).data
        return None


class UserCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ["id", "phone", "first_name_ar", "last_name_ar", "role", "is_active", "password"]
        read_only_fields = ["id"]

    def validate_password(self, value):
        try:
            validate_password(value)
        except ValidationError as e:
            raise serializers.ValidationError(list(e.messages))
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User.objects.create_user(**validated_data, password=password)
        return user


class UserUpdateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8, required=False)

    class Meta:
        model = User
        fields = ["id", "phone", "first_name_ar", "last_name_ar", "role", "is_active", "password"]
        read_only_fields = ["id"]

    def validate_password(self, value):
        if value:
            try:
                validate_password(value)
            except ValidationError as e:
                raise serializers.ValidationError(list(e.messages))
        return value

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance


class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)
    password = serializers.CharField(max_length=128)
    remember_me = serializers.BooleanField(default=False)


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, min_length=8)
