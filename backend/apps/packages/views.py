from django.db import models
from django.db.models import Case, IntegerField, Value, When
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from apps.accounts.permissions import IsManagementOrAbove, is_super_admin

from .models import SubscriptionPackage
from .serializers import SubscriptionPackageSerializer


class SubscriptionPackageViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionPackageSerializer
    search_fields = ["name"]

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsManagementOrAbove()]
        return [IsAuthenticated()]

    def get_queryset(self):
        tag_order = Case(
            When(tag="discount", then=Value(0)),
            When(tag="special", then=Value(1)),
            When(tag="normal", then=Value(2)),
            output_field=IntegerField(),
        )
        queryset = SubscriptionPackage.objects.annotate(tag_priority=tag_order)
        if not is_super_admin(self.request.user):
            queryset = queryset.filter(is_active=True)
        department_id = self.request.query_params.get("department")
        if department_id:
            queryset = queryset.filter(
                models.Q(department_id=department_id) | models.Q(department__isnull=True)
            )
        return queryset.order_by("tag_priority", "order")
