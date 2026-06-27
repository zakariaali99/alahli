from rest_framework import serializers

from .models import SubscriptionPackage


class SubscriptionPackageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPackage
        fields = "__all__"
