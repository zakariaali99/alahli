from django.db.models import Q
from django_filters import rest_framework as filters

from .models import Athlete, RegistrationRequest


class AthleteFilter(filters.FilterSet):
    department = filters.NumberFilter(field_name="department_id")
    sport = filters.NumberFilter(method="filter_sport")
    gender = filters.ChoiceFilter(choices=Athlete.Gender.choices)
    is_active = filters.BooleanFilter()

    def filter_sport(self, queryset, name, value):
        return queryset.filter(
            Q(sport_id=value)
            | Q(sport__isnull=True)
            | Q(subscriptions__package__sport_id=value)
        ).distinct()

    class Meta:
        model = Athlete
        fields = ["department", "sport", "gender", "is_active"]


class RegistrationRequestFilter(filters.FilterSet):
    department = filters.NumberFilter(method="filter_department")
    sport = filters.NumberFilter(method="filter_sport")
    user = filters.NumberFilter(field_name="user_id")

    def filter_department(self, queryset, name, value):
        return queryset.filter(
            Q(athlete__department_id=value)
            | Q(athlete__isnull=True, user__academy_id=value)
            | Q(athlete__isnull=True, user__academy__isnull=True)
        )

    def filter_sport(self, queryset, name, value):
        return queryset.filter(
            Q(athlete__sport_id=value)
            | Q(athlete__isnull=True, user__preferred_sport_id=value)
        )

    class Meta:
        model = RegistrationRequest
        fields = ["status", "role_choice", "user", "department"]

