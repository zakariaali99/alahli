import datetime

from dateutil.relativedelta import relativedelta
from django.conf import settings
from django.db import transaction
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsReceptionOrAbove
from apps.athletes.models import Athlete, ParentAthlete
from apps.departments.models import Group, Sport
from apps.packages.models import SubscriptionPackage

from .models import AttendanceLog, Renewal, Subscription
from .serializers import (
    AttendanceLogSerializer,
    CheckoutSerializer,
    RenewSubscriptionSerializer,
    SubscriptionSerializer,
)


class SubscriptionViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionSerializer
    filterset_fields = ["status", "athlete", "payment_method"]
    search_fields = ["athlete__full_name", "athlete__membership_number"]

    def get_queryset(self):
        user = self.request.user
        base = Subscription.objects.all().select_related(
            "athlete__department", "group", "approved_by",
        ).prefetch_related("renewals")
        if getattr(user, "academy", None) is not None:
            base = base.filter(athlete__department=user.academy)
        if hasattr(user, "athlete") and user.athlete is not None:
            return base.filter(athlete=user.athlete)
        if user.role == "parent":
            athlete_ids = ParentAthlete.objects.filter(parent=user).values_list("athlete_id", flat=True)
            return base.filter(athlete_id__in=athlete_ids)
        return base

    def perform_update(self, serializer):
        import datetime
        instance = serializer.instance
        old_status = instance.status
        updated_instance = serializer.save()
        if old_status != updated_instance.status and updated_instance.status == Subscription.Status.ACTIVE:
            updated_instance.approved_by = self.request.user
            updated_instance.approved_at = datetime.datetime.now()
            updated_instance.save(update_fields=["approved_by", "approved_at"])

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

        new_start = datetime.date.today()
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

    @action(detail=False, methods=["get"])
    def bank_details(self, request):
        group_id = request.query_params.get("group_id")
        if not group_id:
            return Response({"detail": "group_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            group = Group.objects.select_related("sport__department").get(id=group_id)
        except Group.DoesNotExist:
            return Response({"detail": "Group not found"}, status=status.HTTP_404_NOT_FOUND)
        department = group.sport.department
        return Response({
            "account_number": department.bank_account_number or "",
            "iban": department.iban or "",
        })

    @transaction.atomic
    @action(detail=False, methods=["post"])
    def checkout(self, request):
        serializer = CheckoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        user = request.user

        group = Group.objects.select_related("sport__department").get(id=data["group_id"])
        if group.sport_id != data["sport_id"]:
            return Response(
                {"group_id": "Group does not belong to the selected sport"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        package = SubscriptionPackage.objects.get(id=data["package_id"])

        if user.role == "parent":
            athlete_id = data.get("athlete_id")
            if not athlete_id:
                return Response(
                    {"athlete_id": "Required for parent accounts"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if not ParentAthlete.objects.filter(parent=user, athlete_id=athlete_id).exists():
                return Response(
                    {"athlete_id": "Athlete not found under your account"},
                    status=status.HTTP_403_FORBIDDEN,
                )
            athlete = Athlete.objects.get(id=athlete_id)
            parent_athlete_ids = ParentAthlete.objects.filter(parent=user).values_list("athlete_id", flat=True)
            active_subs_count = Subscription.objects.filter(
                athlete_id__in=parent_athlete_ids,
                package_name=package.name,
                status=Subscription.Status.ACTIVE
            ).count()
            if active_subs_count >= package.max_athletes:
                return Response(
                    {"detail": f"هذه الباقة تسمح بحد أقصى {package.max_athletes} لاعبين فقط. لقد وصلت للحد الأقصى بالفعل."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            if not hasattr(user, "athlete") or user.athlete is None:
                return Response(
                    {"detail": "No athlete profile found"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            athlete = user.athlete

        now = datetime.date.today()
        if package.duration_type == "weeks":
            end = now + relativedelta(weeks=package.duration_value)
        else:
            end = now + relativedelta(months=package.duration_value)

        subscription = Subscription.objects.create(
            athlete=athlete,
            package_name=package.name,
            start_date=now,
            end_date=end,
            amount=package.price,
            payment_method=data["payment_method"],
            group=group,
            status=Subscription.Status.PENDING,
        )

        if data.get("invoice_pdf"):
            subscription.invoice_pdf = data["invoice_pdf"]
            subscription.save(update_fields=["invoice_pdf"])

        bank_details = None
        if data["payment_method"] == "bank_transfer":
            department = group.sport.department
            bank_details = {
                "account_number": department.bank_account_number or "",
                "iban": department.iban or "",
            }

        response_data = {
            "status": "pending",
            "subscription_id": subscription.id,
            "message": "تم إرسال طلب الاشتراك، يرجى انتظار التأكيد على هاتفك.",
        }
        if bank_details:
            response_data.update(bank_details)

        return Response(response_data, status=status.HTTP_201_CREATED)


class AttendanceLogViewSet(viewsets.ModelViewSet):
    serializer_class = AttendanceLogSerializer
    filterset_fields = ["athlete"]

    def get_queryset(self):
        user = self.request.user
        base = AttendanceLog.objects.all().select_related("athlete", "verified_by", "subscription")
        if hasattr(user, "athlete") and user.athlete is not None:
            return base.filter(athlete=user.athlete)
        return base

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsReceptionOrAbove()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(verified_by=self.request.user)
