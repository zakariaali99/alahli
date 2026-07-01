from rest_framework import serializers

from apps.athletes.serializers import AthleteDetailSerializer

from .validators import validate_libyan_phone

from .models import User


def _build_photo_url(self, data):
    request = self.context.get("request")
    if request and data.get("photo"):
        data["photo"] = request.build_absolute_uri(data["photo"])
    return data


class UserSerializer(serializers.ModelSerializer):
    athlete_detail = serializers.SerializerMethodField()
    academy_name = serializers.CharField(source="academy.name_ar", read_only=True, default="")

    class Meta:
        model = User
        fields = ["id", "phone", "first_name_ar", "last_name_ar", "full_name_ar", "role", "is_superuser", "is_active", "photo", "athlete_detail", "academy", "academy_name"]
        read_only_fields = ["id"]

    def get_athlete_detail(self, obj):
        athlete = getattr(obj, "athlete", None)
        if athlete is not None:
            return AthleteDetailSerializer(athlete, context=self.context).data
        return None

    def to_representation(self, instance):
        return _build_photo_url(self, super().to_representation(instance))


class UserCreateSerializer(serializers.ModelSerializer):
    phone = serializers.CharField(max_length=20, validators=[validate_libyan_phone])
    password = serializers.CharField(write_only=True, min_length=1)

    class Meta:
        model = User
        fields = ["id", "phone", "first_name_ar", "last_name_ar", "role", "is_active", "password", "photo", "academy"]
        read_only_fields = ["id"]

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User.objects.create_user(**validated_data, password=password)
        return user

    def to_representation(self, instance):
        return _build_photo_url(self, super().to_representation(instance))


class UserUpdateSerializer(serializers.ModelSerializer):
    phone = serializers.CharField(max_length=20, validators=[validate_libyan_phone], required=False)
    password = serializers.CharField(write_only=True, min_length=1, required=False)

    class Meta:
        model = User
        fields = ["id", "phone", "first_name_ar", "last_name_ar", "role", "is_active", "password", "photo", "academy"]
        read_only_fields = ["id"]

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance

    def to_representation(self, instance):
        return _build_photo_url(self, super().to_representation(instance))


class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20, validators=[validate_libyan_phone])
    password = serializers.CharField(max_length=128)
    remember_me = serializers.BooleanField(default=False)


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, min_length=1)
