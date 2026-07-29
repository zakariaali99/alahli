from datetime import date

from rest_framework import serializers

from apps.accounts.validators import validate_libyan_phone

from .models import Athlete, ParentAthlete, RegistrationRequest

PASSWORD_HELP = "أقل شيء حرف واحد"


class AthleteListSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source="department.name_ar", read_only=True)
    sport_name = serializers.CharField(source="sport.name_ar", read_only=True, allow_null=True)
    subscription_end_date = serializers.SerializerMethodField()

    class Meta:
        model = Athlete
        fields = [
            "id", "membership_number", "full_name", "phone",
            "gender", "department", "department_name", "sport", "sport_name",
            "photo", "is_active", "created_at", "subscription_end_date",
        ]

    def get_subscription_end_date(self, obj):
        sub = obj.subscriptions.filter(status="active").order_by("-end_date").first()
        if sub:
            return str(sub.end_date)
        sub = obj.subscriptions.order_by("-end_date").first()
        return str(sub.end_date) if sub else None

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get("request")
        if request and data.get("photo"):
            data["photo"] = request.build_absolute_uri(data["photo"])
        return data


class AthleteDetailSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source="department.name_ar", read_only=True)
    is_active = serializers.BooleanField(required=False, default=True)
    age = serializers.SerializerMethodField()

    class Meta:
        model = Athlete
        fields = "__all__"
        read_only_fields = ["membership_number", "qr_code"]

    def get_age(self, obj):
        if not obj.birth_date:
            return None
        today = date.today()
        return today.year - obj.birth_date.year - (
            (today.month, today.day) < (obj.birth_date.month, obj.birth_date.day)
        )

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
    athlete_department_name = serializers.CharField(
        source="athlete.department.name_ar", read_only=True, allow_null=True
    )
    has_parent = serializers.SerializerMethodField()
    parent_name = serializers.SerializerMethodField()
    parent_phone = serializers.SerializerMethodField()

    class Meta:
        model = RegistrationRequest
        fields = "__all__"
        read_only_fields = ["status", "reviewed_by", "reviewed_at", "rejection_reason"]

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

    def get_has_parent(self, obj):
        athlete = getattr(obj, "athlete", None)
        if athlete is None:
            return False
        return athlete.parents.exists()

    def get_parent_name(self, obj):
        athlete = getattr(obj, "athlete", None)
        if athlete is None:
            return None
        parent_link = athlete.parents.first()
        if parent_link is None:
            return None
        return parent_link.parent.full_name_ar

    def get_parent_phone(self, obj):
        athlete = getattr(obj, "athlete", None)
        if athlete is None:
            return None
        parent_link = athlete.parents.first()
        if parent_link is None:
            return None
        return parent_link.parent.phone


class RegistrationApproveSerializer(serializers.Serializer):
    athlete_id = serializers.IntegerField(required=False, help_text="Athlete ID to approve")


class RegistrationRejectSerializer(serializers.Serializer):
    reason = serializers.CharField(required=True, allow_blank=False)


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
    phone = serializers.CharField(max_length=20, validators=[validate_libyan_phone])
    whatsapp_phone = serializers.CharField(max_length=20, required=False, allow_blank=True, default="")
    password = serializers.CharField(write_only=True, required=False, allow_blank=True, default="")
    photo = serializers.CharField(required=False, allow_null=True, help_text="Base64 camera capture or file upload")
    birth_day = serializers.IntegerField(required=False, allow_null=True, default=None)
    birth_month = serializers.IntegerField(required=False, allow_null=True, default=None)
    birth_year = serializers.IntegerField(required=False, allow_null=True, default=None)
    department = serializers.IntegerField(required=False, allow_null=True, help_text="Department ID for the athlete")
    sport = serializers.IntegerField(required=False, allow_null=True, help_text="Sport ID for the athlete or preferred sport for parent")
    residence = serializers.CharField(max_length=200, required=False, allow_blank=True, default="")
    health_status = serializers.CharField(required=False, allow_blank=True, default="")
    parent_name = serializers.CharField(max_length=100, required=False, allow_blank=True, default="")
    parent_phone = serializers.CharField(max_length=20, required=False, allow_blank=True, default="")

    def validate_birth_date(self, attrs):
        import datetime
        day = attrs.get("birth_day")
        month = attrs.get("birth_month")
        year = attrs.get("birth_year")
        if day is None or month is None or year is None:
            # Default fallback date for parent role
            return datetime.date(1990, 1, 1)
        try:
            return datetime.date(year, month, day)
        except ValueError as e:
            raise serializers.ValidationError({"birth_date": str(e)})


    def validate_phone(self, value):
        from django.contrib.auth import get_user_model
        User = get_user_model()
        user = User.objects.filter(phone=value).first()
        if user:
            if user.registration_requests.filter(status="rejected").exists():
                raise serializers.ValidationError(
                    "هذا الرقم مسجل لحساب مرفوض. يرجى تسجيل الدخول إلى حسابك المرفوض وحذفه أولاً."
                )
            raise serializers.ValidationError("رقم الهاتف هذا مسجل بالفعل")
        return value

    def validate(self, attrs):
        if attrs["role"] == "athlete":
            if not attrs.get("photo"):
                raise serializers.ValidationError({"photo": "الصورة مطلوبة للرياضيين"})
        else:
            attrs.pop("photo", None)

        department_id = attrs.get("department")
        if department_id is not None:
            from apps.departments.models import Department
            if not Department.objects.filter(id=department_id).exists():
                raise serializers.ValidationError({"department": "رقم الأكاديمية غير صحيح"})

        sport_id = attrs.get("sport")
        if sport_id is not None:
            from apps.departments.models import Sport
            if not Sport.objects.filter(id=sport_id).exists():
                raise serializers.ValidationError({"sport": "رقم الرياضة غير صحيح"})

        attrs["birth_date"] = self.validate_birth_date(attrs)
        return attrs
