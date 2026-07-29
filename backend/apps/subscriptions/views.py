import datetime

from dateutil.relativedelta import relativedelta
from django.db import transaction
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import (
    IsManagementOrAbove,
    IsStaffOrAbove,
    is_management_staff,
    is_super_admin,
    scope_by_academy,
)
from apps.athletes.models import Athlete, ParentAthlete
from apps.departments.models import Group
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
        base = scope_by_academy(user, base, academy_field="athlete__department")
        if hasattr(user, "athlete") and user.athlete is not None:
            return base.filter(athlete=user.athlete)
        if user.role == "parent":
            athlete_ids = ParentAthlete.objects.filter(parent=user).values_list("athlete_id", flat=True)
            return base.filter(athlete_id__in=athlete_ids)
        return base

    def perform_create(self, serializer):
        user = self.request.user
        is_staff = is_super_admin(user) or user.role in ["reception", "academy_manager"]
        if is_staff:
            serializer.save(
                status=Subscription.Status.ACTIVE,
                approved_by=user,
                approved_at=timezone.now(),
            )
        else:
            serializer.save()

    def perform_update(self, serializer):
        instance = serializer.instance
        old_status = instance.status
        updated_instance = serializer.save()
        if old_status != updated_instance.status and updated_instance.status == Subscription.Status.ACTIVE:
            updated_instance.approved_by = self.request.user
            updated_instance.approved_at = timezone.now()
            updated_instance.save(update_fields=["approved_by", "approved_at"])
        elif old_status != updated_instance.status and updated_instance.status == Subscription.Status.REJECTED:
            from apps.notifications.models import Notification
            Notification.objects.create(
                athlete=updated_instance.athlete,
                title="تم رفض الاشتراك",
                body=updated_instance.rejection_reason,
            )

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsManagementOrAbove()]
        return [IsAuthenticated()]

    @transaction.atomic
    @action(detail=True, methods=["post"])
    def renew(self, request, pk=None):
        subscription = self.get_object()
        user = request.user

        if not (is_super_admin(user) or user.role in ["reception", "academy_manager"]):
            if hasattr(user, "athlete") and user.athlete is not None:
                if subscription.athlete != user.athlete:
                    return Response(
                        {"detail": "لا يمكنك تجديد اشتراك رياضي آخر"},
                        status=status.HTTP_403_FORBIDDEN,
                    )
            elif user.role == "parent":
                if not ParentAthlete.objects.filter(parent=user, athlete=subscription.athlete).exists():
                    return Response(
                        {"detail": "لا يمكنك تجديد اشتراك هذا الرياضي"},
                        status=status.HTTP_403_FORBIDDEN,
                    )
            else:
                return Response(
                    {"detail": "ليس لديك صلاحية لتجديد الاشتراكات"},
                    status=status.HTTP_403_FORBIDDEN,
                )

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
            created_by=user,
        )

        return Response(SubscriptionSerializer(subscription).data)

    @action(detail=False, methods=["get"])
    def bank_details(self, request):
        group_id = request.query_params.get("group_id")
        if not group_id:
            return Response({"detail": "معرف المجموعة مطلوب"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            group = Group.objects.select_related("sport__department").get(id=group_id)
        except Group.DoesNotExist:
            return Response({"detail": "المجموعة غير موجودة"}, status=status.HTTP_404_NOT_FOUND)
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
                {"group_id": "المجموعة لا تنتمي إلى الرياضة المحددة"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        package = SubscriptionPackage.objects.get(id=data["package_id"])

        if user.role == "parent":
            athlete_id = data.get("athlete_id")
            if not athlete_id:
                return Response(
                    {"athlete_id": "مطلوب لحسابات أولياء الأمور"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if not ParentAthlete.objects.filter(parent=user, athlete_id=athlete_id).exists():
                return Response(
                    {"athlete_id": "الرياضي غير موجود ضمن حسابك"},
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
                    {"detail": f"هذه الباقة تسمح بحد أقصى {package.max_athletes} رياضيين فقط. لقد وصلت للحد الأقصى بالفعل."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            athlete = getattr(user, "athlete", None)

            if athlete is None:
                reg = user.registration_requests.select_related("athlete").order_by("-created_at").first()
                if reg and hasattr(reg, "athlete") and reg.athlete:
                    athlete = reg.athlete

            if athlete is None:
                athlete = Athlete.objects.filter(phone=user.phone).first()

            if athlete is None and data.get("athlete_id"):
                try:
                    athlete = Athlete.objects.get(id=data["athlete_id"])
                except Athlete.DoesNotExist:
                    import logging
                    logging.getLogger(__name__).warning(
                        "Athlete ID %s not found for user %s (checkout fallback)",
                        data["athlete_id"], user.id,
                    )

            if athlete is not None and getattr(user, "athlete", None) is None:
                user.athlete = athlete
                user.save(update_fields=["athlete"])

            if athlete is None:
                return Response(
                    {"detail": "لم يتم العثور على ملف رياضي لهذا الحساب"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        now = datetime.date.today()
        if package.duration_type == "weeks":
            end = now + relativedelta(weeks=package.duration_value)
        else:
            end = now + relativedelta(months=package.duration_value)

        has_previous_sub = Subscription.objects.filter(athlete=athlete).exists()
        if has_previous_sub and package.renewal_price > 0:
            sub_amount = package.renewal_price
        elif package.new_price > 0:
            sub_amount = package.new_price
        else:
            sub_amount = package.price

        # Instant activation if initiated by management staff
        is_staff = is_super_admin(user) or user.role in ["reception", "academy_manager"]
        sub_status = Subscription.Status.ACTIVE if is_staff else Subscription.Status.PENDING

        subscription = Subscription.objects.create(
            athlete=athlete,
            package_name=package.name,
            start_date=now,
            end_date=end,
            amount=sub_amount,
            payment_method=data["payment_method"],
            group=group,
            shift_name=data.get("shift_name", ""),
            status=sub_status,
            approved_by=user if is_staff else None,
            approved_at=timezone.now() if is_staff else None,
        )

        if data.get("invoice_pdf"):
            subscription.invoice_pdf = data["invoice_pdf"]
            subscription.save(update_fields=["invoice_pdf"])

        if not is_staff:
            try:
                from apps.notifications.services import send_admin_push_sync

                send_admin_push_sync(
                    title="اشتراك جديد بانتظار الموافقة",
                    body=f"طلب اشتراك جديد لـ {athlete.full_name} - باقة {package.name}",
                    notification_type="new_subscription",
                    entity_id=subscription.id,
                )
            except Exception:
                import logging
                logging.getLogger(__name__).exception("Failed to send push notification for subscription")

        bank_details = None
        if data["payment_method"] == "bank_transfer":
            department = group.sport.department
            bank_details = {
                "account_number": department.bank_account_number or "",
                "iban": department.iban or "",
            }

        response_data = {
            "status": subscription.status,
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
        base = scope_by_academy(user, base, academy_field="athlete__department")
        if hasattr(user, "athlete") and user.athlete is not None:
            return base.filter(athlete=user.athlete)
        return base

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsStaffOrAbove()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(verified_by=self.request.user)
