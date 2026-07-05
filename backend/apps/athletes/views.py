import base64
import datetime
import secrets
import uuid

from django.core.files.base import ContentFile
from django.db import transaction
from rest_framework import status, viewsets
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from apps.accounts.models import User
from apps.accounts.permissions import (
    IsManagementOrAbove,
    IsStaffOrAbove,
    IsSuperAdmin,
    is_staff_user,
    scope_by_academy,
)
from apps.accounts.serializers import UserSerializer
from apps.accounts.validators import validate_libyan_phone
from apps.subscriptions.models import Subscription

from .filters import AthleteFilter
from .models import Athlete, ParentAthlete, RegistrationRequest
from .serializers import (
    AthleteDetailSerializer,
    AthleteListSerializer,
    ParentAthleteSerializer,
    RegisterSerializer,
    RegistrationApproveSerializer,
    RegistrationRequestSerializer,
    RegistrationRejectSerializer,
)


def _split_full_name(full_name: str) -> tuple[str, str]:
    normalized = (full_name or "").strip()
    if not normalized:
        return "", ""

    parts = normalized.split()
    if len(parts) == 1:
        return parts[0], ""
    return parts[0], " ".join(parts[1:])


@api_view(["POST"])
@permission_classes([AllowAny])
def register_view(request):
    serializer = RegisterSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    photo_file = None
    if serializer.validated_data["role"] == "athlete":
        photo_data = serializer.validated_data.get("photo")
        if photo_data:
            try:
                img_format, imgstr = photo_data.split(";base64,", 1)
                ext = img_format.split("/")[-1] if "/" in img_format else "jpg"
                photo_file = ContentFile(base64.b64decode(imgstr), name=f"{uuid.uuid4().hex}.{ext}")
            except (ValueError, IndexError, TypeError):
                return Response({"photo": "Invalid photo format"}, status=status.HTTP_400_BAD_REQUEST)

    with transaction.atomic():
        user = User.objects.create_user(
            phone=serializer.validated_data["phone"],
            first_name_ar=serializer.validated_data["full_name"],
            last_name_ar="",
            password=serializer.validated_data["password"],
            role=serializer.validated_data["role"],
            is_active=False,
        )

        registration = RegistrationRequest.objects.create(
            user=user,
            role_choice=serializer.validated_data["role"],
        )

        if serializer.validated_data["role"] == "athlete":
            athlete = Athlete.objects.create(
                full_name=serializer.validated_data["full_name"],
                phone=serializer.validated_data["phone"],
                birth_date=serializer.validated_data["birth_date"],
                gender="male",
                photo=photo_file,
                notes="",
                is_active=False,
                registration=registration,
                department_id=serializer.validated_data.get("department"),
            )
            user.athlete = athlete
            user.save(update_fields=["athlete"])

    try:
        from apps.notifications.services import send_admin_push_sync

        role = serializer.validated_data["role"]
        role_label = "لاعب" if role == "athlete" else "ولي أمر"
        send_admin_push_sync(
            title=f"تسجيل {role_label} جديد",
            body=f"طلب تسجيل جديد من {role_label} {serializer.validated_data['full_name']} - {serializer.validated_data['phone']}",
            notification_type="new_registration",
            entity_id=registration.id,
        )
    except Exception:
        import logging
        logging.getLogger(__name__).exception("Failed to send push notification for registration")

    return Response(
        {"message": "تم التسجيل بنجاح", "registration_id": registration.id},
        status=status.HTTP_201_CREATED,
    )


class AthleteViewSet(viewsets.ModelViewSet):
    queryset = Athlete.objects.select_related("department", "registration")
    filterset_class = AthleteFilter
    search_fields = ["full_name", "membership_number", "phone"]

    def get_queryset(self):
        qs = Athlete.objects.select_related("department", "registration")
        user = self.request.user
        qs = scope_by_academy(user, qs, academy_field="department")
        if not is_staff_user(user):
            return qs.filter(is_active=True)
        return qs

    def get_serializer_class(self):
        if self.action == "list":
            return AthleteListSerializer
        return AthleteDetailSerializer

    def get_permissions(self):
        if self.action == "destroy":
            return [IsSuperAdmin()]
        if self.action in ["create", "update", "partial_update"]:
            return [IsManagementOrAbove()]
        if self.action == "me":
            return [IsAuthenticated()]
        return [IsStaffOrAbove()]

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        password = request.data.get("password", None)
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        athlete = serializer.save()

        first_name, last_name = _split_full_name(athlete.full_name)
        user, created = User.objects.get_or_create(
            phone=athlete.phone,
            defaults={
                "first_name_ar": first_name or athlete.full_name,
                "last_name_ar": last_name,
                "role": User.Role.ATHLETE,
                "is_active": athlete.is_active,
            },
        )

        if created:
            user.set_password(password or secrets.token_urlsafe(16))
        elif password:
            user.set_password(password)

        if user.role != User.Role.ATHLETE:
            user.role = User.Role.ATHLETE

        user.first_name_ar = first_name or user.first_name_ar or athlete.full_name
        user.last_name_ar = last_name
        user.athlete = athlete
        user.is_active = athlete.is_active
        user.save()

        headers = self.get_success_headers(serializer.data)
        response_data = self.get_serializer(athlete).data
        return Response(response_data, status=status.HTTP_201_CREATED, headers=headers)

    @action(detail=False, methods=["get"])
    def me(self, request):
        user = request.user
        if user.athlete:
            serializer = AthleteDetailSerializer(user.athlete, context={"request": request})
            return Response(serializer.data)
        linked = Athlete.objects.filter(parents__parent=user)
        if linked.exists():
            serializer = AthleteListSerializer(linked, many=True, context={"request": request})
            return Response(serializer.data)
        return Response({"detail": "لم يتم العثور على ملف رياضي"}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=False, methods=["get"], url_path="verify/(?P<membership_number>[^/.]+)")
    def verify(self, request, membership_number=None):
        try:
            athlete = Athlete.objects.select_related("department").prefetch_related("subscriptions").get(
                membership_number=membership_number, is_active=True
            )
        except Athlete.DoesNotExist:
            return Response(
                {"active": False, "detail": "Membership not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        subscription = athlete.subscriptions.filter(status="active").first()
        return Response({
            "active": bool(subscription),
            "athlete_id": athlete.id,
            "athlete_name": athlete.full_name,
            "department": athlete.department.name_ar if athlete.department else "",
            "expiry_date": subscription.end_date if subscription else None,
            "membership_number": athlete.membership_number,
            "subscription_id": subscription.id if subscription else None,
        })


class RegistrationRequestViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = RegistrationRequestSerializer
    permission_classes = [IsManagementOrAbove]
    filterset_fields = ["status", "role_choice"]

    def get_queryset(self):
        return scope_by_academy(
            self.request.user,
            RegistrationRequest.objects.all().select_related(
                "user", "reviewed_by", "athlete", "athlete__department"
            ).prefetch_related("athlete__parents__parent"),
            academy_field="athlete__department",
        )

    @transaction.atomic
    @action(detail=True, methods=["post"], url_path="create-athlete")
    def create_athlete(self, request, pk=None):
        registration = self.get_object()

        if registration.role_choice != RegistrationRequest.RoleChoice.ATHLETE:
            return Response({"detail": "فقط تسجيلات الرياضيين يمكنها إنشاء ملف رياضي"}, status=status.HTTP_400_BAD_REQUEST)

        if hasattr(registration, "athlete") and registration.athlete:
            return Response(
                AthleteDetailSerializer(registration.athlete, context={"request": request}).data,
                status=status.HTTP_200_OK,
            )

        serializer = AthleteDetailSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        athlete = serializer.save(registration=registration, is_active=False)

        user = registration.user
        user.athlete = athlete
        if user.role != User.Role.ATHLETE:
            user.role = User.Role.ATHLETE
        user.save(update_fields=["athlete", "role"])

        return Response(AthleteDetailSerializer(athlete, context={"request": request}).data, status=status.HTTP_201_CREATED)

    @transaction.atomic
    @action(detail=True, methods=["post"])
    def approve(self, request, pk=None):
        registration = self.get_object()
        if registration.status != RegistrationRequest.Status.PENDING:
            return Response({"detail": "تمت معالجة طلب التسجيل بالفعل"}, status=status.HTTP_400_BAD_REQUEST)

        if registration.role_choice == RegistrationRequest.RoleChoice.ATHLETE and not hasattr(registration, "athlete"):
            return Response({"detail": "يرجى إنشاء ملف رياضي أولاً"}, status=status.HTTP_400_BAD_REQUEST)

        registration.status = RegistrationRequest.Status.APPROVED
        registration.reviewed_by = request.user
        registration.reviewed_at = datetime.datetime.now()
        registration.save()

        athlete = getattr(registration, "athlete", None)
        if athlete:
            subscription = athlete.subscriptions.filter(status=Subscription.Status.PENDING).first()
            if subscription:
                subscription.status = Subscription.Status.ACTIVE
                subscription.approved_by = request.user
                subscription.approved_at = datetime.datetime.now()
                subscription.save()
            athlete.is_active = True
            athlete.save(update_fields=["is_active"])

        return Response({"detail": "تم قبول طلب التسجيل", "registration_id": registration.id})

    @action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        registration = self.get_object()
        if registration.status != RegistrationRequest.Status.PENDING:
            return Response({"detail": "تمت معالجة طلب التسجيل بالفعل"}, status=status.HTTP_400_BAD_REQUEST)

        serializer = RegistrationRejectSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reason = serializer.validated_data.get("reason", "")

        # Delete registration and linked athlete (cascade)
        registration.delete()

        # Delete the user if it was a public registration (athlete/parent role)
        user = registration.user
        if user and user.role in ['athlete', 'parent']:
            user.delete()

        return Response({"detail": "تم رفض طلب التسجيل وحذف الحساب"})


class ParentAthleteViewSet(viewsets.ModelViewSet):
    serializer_class = ParentAthleteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return ParentAthlete.objects.filter(parent=self.request.user).select_related("athlete")

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        athlete_id = request.data.get("athlete")
        if athlete_id and str(athlete_id).isdigit():
            serializer = self.get_serializer(data={
                "athlete": athlete_id,
                "relationship": request.data.get("relationship", ""),
            })
            serializer.is_valid(raise_exception=True)
            self.perform_create(serializer)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        full_name = request.data.get("full_name")
        phone = request.data.get("phone")
        photo_data = request.data.get("photo")
        birth_day = request.data.get("birth_day")
        birth_month = request.data.get("birth_month")
        birth_year = request.data.get("birth_year")

        if not full_name or not phone:
            return Response({"detail": "full_name and phone are required"}, status=status.HTTP_400_BAD_REQUEST)

        phone = validate_libyan_phone(phone)
        if not photo_data:
            return Response({"detail": "photo is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            birth_date = datetime.date(int(birth_year), int(birth_month), int(birth_day))
        except (ValueError, TypeError, OverflowError):
            return Response({"detail": "Invalid birth date"}, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(phone=phone).exists() or Athlete.objects.filter(phone=phone).exists():
            return Response({"detail": "Phone already exists"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            img_format, imgstr = photo_data.split(";base64,")
            ext = img_format.split("/")[-1] if "/" in img_format else "jpg"
            photo_file = ContentFile(base64.b64decode(imgstr), name=f"{uuid.uuid4().hex}.{ext}")
        except (ValueError, IndexError, TypeError):
            return Response({"detail": "Invalid photo format"}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(
            phone=phone,
            first_name_ar=full_name,
            last_name_ar="",
            password=secrets.token_urlsafe(16),
            role="athlete",
        )
        registration = RegistrationRequest.objects.create(
            user=user,
            role_choice=RegistrationRequest.RoleChoice.ATHLETE,
        )

        athlete = Athlete.objects.create(
            full_name=full_name,
            phone=phone,
            birth_date=birth_date,
            gender="male",
            photo=photo_file,
            notes="",
            is_active=False,
            registration=registration,
        )
        user.athlete = athlete
        user.save(update_fields=["athlete"])

        parent_link = ParentAthlete.objects.create(parent=request.user, athlete=athlete)
        return Response(ParentAthleteSerializer(parent_link).data, status=status.HTTP_201_CREATED)

    def perform_create(self, serializer):
        serializer.save(parent=self.request.user)

    @action(detail=False, methods=["get"])
    def children(self, request):
        athletes = Athlete.objects.filter(parents__parent=request.user)
        serializer = AthleteDetailSerializer(athletes, many=True, context={"request": request})
        return Response(serializer.data)
