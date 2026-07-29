from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from apps.accounts.permissions import (
    IsManagementOrAbove,
    IsStaffOrAbove,
    IsSuperAdmin,
    scope_by_academy,
)

from .models import Department, Group, Sport
from .serializers import DepartmentSerializer, GroupSerializer, SportSerializer


class DepartmentViewSet(viewsets.ModelViewSet):
    queryset = Department.objects.all()
    serializer_class = DepartmentSerializer
    search_fields = ["name", "name_ar"]

    def create(self, request, *args, **kwargs):
        from rest_framework.response import Response
        from rest_framework import status
        return Response(
            {"detail": "النظام محدد بالأكاديميتين الأساسيتين فقط ولا يمكن إضافة أكاديميات جديدة"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    def destroy(self, request, *args, **kwargs):
        from rest_framework.response import Response
        from rest_framework import status
        return Response(
            {"detail": "لا يمكن حذف الأكاديميات الأساسية بالنظام"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    def get_permissions(self):
        if self.action in ["update", "partial_update"]:
            return [IsSuperAdmin()]
        if self.action in ["list", "retrieve"]:
            return []
        return [IsStaffOrAbove()]


class SportViewSet(viewsets.ModelViewSet):
    queryset = Sport.objects.all().select_related("department")
    serializer_class = SportSerializer
    search_fields = ["name", "name_ar"]
    filterset_fields = ["department", "is_active"]

    def get_queryset(self):
        qs = Sport.objects.all().select_related("department")
        return scope_by_academy(self.request.user, qs, academy_field="department", request=self.request)

    def get_permissions(self):
        if self.action == "destroy":
            return [IsSuperAdmin()]
        if self.action in ["create", "update", "partial_update"]:
            return [IsManagementOrAbove()]
        if self.action in ["list", "retrieve"]:
            return [IsAuthenticated()]
        return [IsStaffOrAbove()]


class GroupViewSet(viewsets.ModelViewSet):
    queryset = Group.objects.all().select_related("sport", "coach")
    serializer_class = GroupSerializer
    search_fields = ["name", "name_ar"]
    filterset_fields = ["sport", "coach", "is_active"]

    def get_queryset(self):
        qs = Group.objects.all().select_related("sport", "coach")
        return scope_by_academy(self.request.user, qs, academy_field="sport__department", request=self.request)

    def get_permissions(self):
        if self.action == "destroy":
            return [IsSuperAdmin()]
        if self.action in ["create", "update", "partial_update"]:
            return [IsManagementOrAbove()]
        if self.action in ["list", "retrieve"]:
            return [IsAuthenticated()]
        return [IsStaffOrAbove()]
