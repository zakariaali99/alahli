from django_filters import rest_framework as filters

from .models import Athlete


class AthleteFilter(filters.FilterSet):
    department = filters.NumberFilter(field_name="department_id")
    gender = filters.ChoiceFilter(choices=Athlete.Gender.choices)
    is_active = filters.BooleanFilter()

    class Meta:
        model = Athlete
        fields = ["department", "gender", "is_active"]
