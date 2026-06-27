from datetime import date

from dateutil.relativedelta import relativedelta
from django.db import transaction
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsReceptionOrAbove

from .models import AttendanceLog, Renewal, Subscription
from .serializers import (
    AttendanceLogSerializer,
    RenewSubscriptionSerializer,
    SubscriptionSerializer,
)


class SubscriptionViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionSerializer
    filterset_fields = ["status", "athlete"]
    search_fields = ["athlete__full_name", "athlete__membership_number"]

    def get_queryset(self):
        user = self.request.user
        base = Subscription.objects.all().select_related('athlete__department').prefetch_related('renewals')
        if hasattr(user, "athlete") and user.athlete is not None:
            return base.filter(athlete=user.athlete)
        return base

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy", "renew"]:
            return [IsReceptionOrAbove()]
        return [IsAuthenticated()]

    @transaction.atomic
    @action(detail=True, methods=["post"])
    def renew(self, request, pk=None):
        subscription = self.get_object()
        serializer = RenewSubscriptionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        months = serializer.validated_data["months"]
        amount = serializer.validated_data["amount"]

        new_start = date.today()
        if subscription.end_date > new_start:
            new_start = subscription.end_date

        new_end = new_start + relativedelta(months=months)
        subscription.end_date = new_end
        subscription.status = Subscription.Status.ACTIVE
        subscription.save()

        Renewal.objects.create(
            subscription=subscription,
            amount=amount,
            months=months,
            created_by=request.user,
        )

        return Response(SubscriptionSerializer(subscription).data)


class AttendanceLogViewSet(viewsets.ModelViewSet):
    serializer_class = AttendanceLogSerializer
    filterset_fields = ["athlete"]

    def get_queryset(self):
        user = self.request.user
        base = AttendanceLog.objects.all().select_related('athlete', 'verified_by', 'subscription')
        if hasattr(user, "athlete") and user.athlete is not None:
            return base.filter(athlete=user.athlete)
        return base

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsReceptionOrAbove()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(verified_by=self.request.user)
