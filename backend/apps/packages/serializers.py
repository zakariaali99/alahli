from rest_framework import serializers

from .models import SubscriptionPackage


class SubscriptionPackageSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source="department.name_ar", read_only=True, allow_null=True)

    class Meta:
        model = SubscriptionPackage
        fields = "__all__"
