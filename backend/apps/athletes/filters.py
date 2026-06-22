from django.db import models
from django_filters import rest_framework as filters

from .models import Athlete


class AthleteFilter(filters.FilterSet):
    department = filters.NumberFilter(field_name="department_id")
    gender = filters.ChoiceFilter(choices=Athlete.Gender.choices)
    is_active = filters.BooleanFilter()
    search = filters.CharFilter(method="filter_search")

    class Meta:
        model = Athlete
        fields = ["department", "gender", "is_active"]

    def filter_search(self, queryset, name, value):
        return queryset.filter(
            models.Q(full_name__icontains=value)
            | models.Q(membership_number__icontains=value)
            | models.Q(phone__icontains=value)
        )
