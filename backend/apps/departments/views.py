from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from apps.accounts.permissions import IsReceptionOrAbove

from .models import Department, Group, Sport
from .serializers import DepartmentSerializer, GroupSerializer, SportSerializer


class DepartmentViewSet(viewsets.ModelViewSet):
    queryset = Department.objects.all()
    serializer_class = DepartmentSerializer
    search_fields = ["name", "name_ar"]


class SportViewSet(viewsets.ModelViewSet):
    queryset = Sport.objects.all().select_related("department")
    serializer_class = SportSerializer
    search_fields = ["name", "name_ar"]
    filterset_fields = ["department", "is_active"]

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsReceptionOrAbove()]
        return [IsAuthenticated()]


class GroupViewSet(viewsets.ModelViewSet):
    queryset = Group.objects.all().select_related("sport", "coach")
    serializer_class = GroupSerializer
    search_fields = ["name", "name_ar"]
    filterset_fields = ["sport", "coach", "is_active"]

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsReceptionOrAbove()]
        return [IsAuthenticated()]
