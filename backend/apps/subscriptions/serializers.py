from rest_framework import serializers

from .models import AttendanceLog, Renewal, Subscription


class RenewalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Renewal
        fields = "__all__"
        read_only_fields = ["created_by"]


class SubscriptionSerializer(serializers.ModelSerializer):
    renewals = RenewalSerializer(many=True, read_only=True)
    athlete_name = serializers.CharField(source="athlete.full_name", read_only=True)
    membership_number = serializers.CharField(source="athlete.membership_number", read_only=True)
    department_name = serializers.CharField(source="athlete.department.name_ar", read_only=True)

    class Meta:
        model = Subscription
        fields = "__all__"
        read_only_fields = ["status"]


class RenewSubscriptionSerializer(serializers.Serializer):
    months = serializers.ChoiceField(choices=[1, 3, 6, 12])
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)


class AttendanceLogSerializer(serializers.ModelSerializer):
    athlete_name = serializers.CharField(source="athlete.full_name", read_only=True)

    class Meta:
        model = AttendanceLog
        fields = "__all__"
        read_only_fields = ["checked_in_at", "verified_by"]
