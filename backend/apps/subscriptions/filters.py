from django_filters import rest_framework as filters

from .models import Subscription


class SubscriptionFilter(filters.FilterSet):
    sport = filters.NumberFilter(field_name="athlete__sport")

    class Meta:
        model = Subscription
        fields = ["status", "athlete", "payment_method", "athlete__department"]
