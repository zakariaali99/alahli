from rest_framework import serializers

from apps.packages.models import SubscriptionPackage

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
    group_name = serializers.CharField(source="group.name_ar", read_only=True, default="")
    invoice_pdf_url = serializers.SerializerMethodField()
    package_id = serializers.IntegerField(write_only=True, required=False)

    class Meta:
        model = Subscription
        fields = "__all__"
        read_only_fields = ["approved_by", "approved_at"]

    def get_invoice_pdf_url(self, obj):
        if obj.invoice_pdf:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.invoice_pdf.url)
            return obj.invoice_pdf.url
        return None

    def create(self, validated_data):
        package_id = validated_data.pop("package_id", None)
        if package_id:
            try:
                package = SubscriptionPackage.objects.get(id=package_id)
                validated_data["package_name"] = package.name
                validated_data["amount"] = package.price
            except SubscriptionPackage.DoesNotExist:
                raise serializers.ValidationError({"package_id": "Package not found"})
        return super().create(validated_data)


class RenewSubscriptionSerializer(serializers.Serializer):
    months = serializers.ChoiceField(choices=[1, 3, 6, 12])
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)


class CheckoutSerializer(serializers.Serializer):
    sport_id = serializers.IntegerField()
    group_id = serializers.IntegerField()
    package_id = serializers.IntegerField()
    payment_method = serializers.ChoiceField(choices=["cash", "bank_transfer"])
    invoice_pdf = serializers.FileField(required=False, allow_null=True)
    athlete_id = serializers.IntegerField(required=False, help_text="Required for parent accounts")

    def validate_invoice_pdf(self, value):
        if value:
            if not value.name.endswith(".pdf"):
                raise serializers.ValidationError("Only PDF files are allowed")
            if value.content_type != "application/pdf":
                raise serializers.ValidationError("File must be a PDF")
        return value


class AttendanceLogSerializer(serializers.ModelSerializer):
    athlete_name = serializers.CharField(source="athlete.full_name", read_only=True)

    class Meta:
        model = AttendanceLog
        fields = "__all__"
        read_only_fields = ["checked_in_at", "verified_by"]
