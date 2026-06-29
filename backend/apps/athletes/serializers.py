from rest_framework import serializers

from .models import Athlete, ParentAthlete, RegistrationRequest


class AthleteListSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source="department.name_ar", read_only=True)

    class Meta:
        model = Athlete
        fields = [
            "id", "membership_number", "full_name", "phone",
            "gender", "department", "department_name",
            "photo", "is_active", "created_at",
        ]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get("request")
        if request and data.get("photo"):
            data["photo"] = request.build_absolute_uri(data["photo"])
        return data


class AthleteDetailSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source="department.name_ar", read_only=True)

    class Meta:
        model = Athlete
        fields = "__all__"
        read_only_fields = ["membership_number", "qr_code"]

    def create(self, validated_data):
        return Athlete.objects.create(**validated_data)

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get("request")
        if request and data.get("photo"):
            data["photo"] = request.build_absolute_uri(data["photo"])
        if request and data.get("qr_code"):
            data["qr_code"] = request.build_absolute_uri(data["qr_code"])
        return data


class RegistrationRequestSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source="user.full_name_ar", read_only=True)
    user_phone = serializers.CharField(source="user.phone", read_only=True)
    athlete_id = serializers.SerializerMethodField()
    athlete_name = serializers.SerializerMethodField()
    athlete_photo = serializers.SerializerMethodField()
    athlete_membership_number = serializers.SerializerMethodField()

    class Meta:
        model = RegistrationRequest
        fields = "__all__"
        read_only_fields = ["status", "reviewed_by", "reviewed_at"]

    def get_athlete_id(self, obj):
        athlete = getattr(obj, "athlete", None)
        return athlete.id if athlete else None

    def get_athlete_name(self, obj):
        athlete = getattr(obj, "athlete", None)
        return athlete.full_name if athlete else None

    def get_athlete_photo(self, obj):
        athlete = getattr(obj, "athlete", None)
        if not athlete or not athlete.photo:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(athlete.photo.url)
        return athlete.photo.url

    def get_athlete_membership_number(self, obj):
        athlete = getattr(obj, "athlete", None)
        return athlete.membership_number if athlete else None


class RegistrationApproveSerializer(serializers.Serializer):
    athlete_id = serializers.IntegerField(required=False, help_text="Athlete ID to approve")


class RegistrationRejectSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True)


class ParentAthleteSerializer(serializers.ModelSerializer):
    athlete_name = serializers.CharField(source="athlete.full_name", read_only=True)
    athlete_membership = serializers.CharField(source="athlete.membership_number", read_only=True)

    class Meta:
        model = ParentAthlete
        fields = "__all__"
        read_only_fields = ["created_at"]


class RegisterSerializer(serializers.Serializer):
    role = serializers.ChoiceField(choices=["athlete", "parent"])
    full_name = serializers.CharField(max_length=100)
    phone = serializers.CharField(max_length=20)
    password = serializers.CharField(write_only=True, min_length=8)
    photo = serializers.CharField(required=False, allow_null=True, help_text="Base64 camera capture")
    weight = serializers.FloatField(required=False, allow_null=True)
    height = serializers.FloatField(required=False, allow_null=True)
    birth_day = serializers.IntegerField(min_value=1, max_value=31)
    birth_month = serializers.IntegerField(min_value=1, max_value=12)
    birth_year = serializers.IntegerField(min_value=1900)

    def validate_birth_date(self, attrs):
        import datetime
        day = attrs.get("birth_day")
        month = attrs.get("birth_month")
        year = attrs.get("birth_year")
        try:
            return datetime.date(year, month, day)
        except ValueError as e:
            raise serializers.ValidationError({"birth_date": str(e)})

    def validate(self, attrs):
        from django.contrib.auth.password_validation import validate_password
        from django.core.exceptions import ValidationError

        try:
            validate_password(attrs["password"])
        except ValidationError as e:
            raise serializers.ValidationError({"password": list(e.messages)})

        if attrs["role"] == "athlete":
            if not attrs.get("photo"):
                raise serializers.ValidationError({"photo": "Photo is required for athletes"})
            if attrs.get("weight") is None:
                raise serializers.ValidationError({"weight": "Weight is required for athletes"})
            if attrs.get("height") is None:
                raise serializers.ValidationError({"height": "Height is required for athletes"})
        else:
            attrs.pop("photo", None)
            attrs.pop("weight", None)
            attrs.pop("height", None)

        attrs["birth_date"] = self.validate_birth_date(attrs)
        return attrs
