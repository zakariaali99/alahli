import base64
import datetime
import secrets
import uuid

from django.core.files.base import ContentFile
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from apps.accounts.models import User
from apps.accounts.permissions import (
    IsManagementOrAbove,
    IsManagerOrAbove,
    IsStaffOrAbove,
    is_management_staff,
    is_staff_user,
    scope_by_academy,
)
from apps.accounts.validators import validate_libyan_phone
from apps.subscriptions.models import Subscription

from .filters import AthleteFilter, RegistrationRequestFilter
from .models import Athlete, ParentAthlete, RegistrationRequest
from .serializers import (
    AthleteDetailSerializer,
    AthleteListSerializer,
    ParentAthleteSerializer,
    ParentUpdateSerializer,
    RegisterSerializer,
    RegistrationRejectSerializer,
    RegistrationRequestSerializer,
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

    dept_id = serializer.validated_data.get("department")
    role = serializer.validated_data["role"]
    if dept_id:
        from apps.departments.models import Department
        dept = Department.objects.filter(id=dept_id).first()
        if dept:
            name_ar_norm = dept.name_ar.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
            if "اوس" in name_ar_norm or "aws" in dept.name.lower():
                role = "parent"
            elif "اهلي" in name_ar_norm or "ahli" in dept.name.lower():
                # Allow parent role if explicitly selected for Al-Ahly (e.g. Karate)
                if serializer.validated_data.get("role") == "parent":
                    role = "parent"
                else:
                    role = "athlete"


    photo_file = None
    if role == "athlete":
        photo_data = serializer.validated_data.get("photo")
        if photo_data:
            try:
                img_format, imgstr = photo_data.split(";base64,", 1)
                ext = img_format.split("/")[-1] if "/" in img_format else "jpg"
                photo_file = ContentFile(base64.b64decode(imgstr), name=f"{uuid.uuid4().hex}.{ext}")
            except (ValueError, IndexError, TypeError):
                return Response({"photo": "تنسيق الصورة غير صالح"}, status=status.HTTP_400_BAD_REQUEST)

    raw_password = serializer.validated_data.get("password") or secrets.token_urlsafe(16)
    residence = serializer.validated_data.get("residence", "")
    health_status = serializer.validated_data.get("health_status", "")
    whatsapp_phone = serializer.validated_data.get("whatsapp_phone", "")
    if role == "parent":
        # Al Aws parents provide a single WhatsApp number; reuse it as the login phone.
        whatsapp_phone = whatsapp_phone or serializer.validated_data["phone"]
    parent_name = serializer.validated_data.get("parent_name", "")
    parent_phone = serializer.validated_data.get("parent_phone", "")

    # Auto-approve when a staff/management user creates the account
    is_staff_creator = bool(
        request.user
        and request.user.is_authenticated
        and (
            request.user.role in ["super_admin", "academy_manager", "special_manager", "reception", "trainer", "viewer"]
            or request.user.is_staff
            or request.user.is_superuser
        )
    )

    sport_id = serializer.validated_data.get("sport")

    try:
        with transaction.atomic():
            user = User.objects.create_user(
                phone=serializer.validated_data["phone"],
                first_name_ar=serializer.validated_data["full_name"],
                last_name_ar="",
                password=raw_password,
                role=role,
                residence=residence,
                whatsapp_phone=whatsapp_phone,
                is_active=is_staff_creator,
                academy_id=dept_id,
                preferred_sport_id=sport_id if role == "parent" else None,
            )

            reg_status = RegistrationRequest.Status.APPROVED if is_staff_creator else RegistrationRequest.Status.PENDING
            registration = RegistrationRequest.objects.create(
                user=user,
                role_choice=role,
                residence=residence,
                health_status=health_status,
                status=reg_status,
                reviewed_by=request.user if is_staff_creator else None,
                reviewed_at=timezone.now() if is_staff_creator else None,
            )

            if role == "athlete":
                athlete = Athlete.objects.create(
                    full_name=serializer.validated_data["full_name"],
                    phone=serializer.validated_data["phone"],
                    parent_name="",
                    parent_phone="",
                    residence=residence,
                    health_status=health_status,
                    birth_date=serializer.validated_data["birth_date"],
                    gender="male",
                    photo=photo_file,
                    notes="",
                    is_active=is_staff_creator,
                    registration=registration,
                    department_id=dept_id,
                    sport_id=sport_id,
                )
                user.athlete = athlete
                user.save(update_fields=["athlete"])


    except IntegrityError:
        return Response(
            {"detail": {"phone": "رقم الهاتف هذا مسجل بالفعل"}},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if not is_staff_creator:
        try:
            from apps.notifications.services import send_admin_push_sync

            _role = serializer.validated_data["role"]
            role_label = "رياضي" if _role == "athlete" else "ولي أمر"
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
        {
            "message": "تم التسجيل بنجاح",
            "registration_id": registration.id,
            "user_id": user.id,
            "athlete_id": athlete.id if role == "athlete" and 'athlete' in locals() else None,
        },
        status=status.HTTP_201_CREATED,
    )


class AthleteViewSet(viewsets.ModelViewSet):
    queryset = Athlete.objects.select_related("department", "registration")
    filterset_class = AthleteFilter
    search_fields = ["full_name", "membership_number", "phone"]

    def get_queryset(self):
        qs = Athlete.objects.select_related("department", "sport", "registration").prefetch_related("subscriptions", "parents__parent")
        user = self.request.user
        qs = scope_by_academy(user, qs, academy_field="department", request=self.request)
        if not is_staff_user(user):
            return qs.filter(is_active=True)
        return qs

    def get_serializer_class(self):
        if self.action == "list":
            return AthleteListSerializer
        return AthleteDetailSerializer

    def get_permissions(self):
        if self.action == "destroy":
            return [IsManagerOrAbove()]
        if self.action == "create":
            return [IsManagementOrAbove()]
        if self.action in ["update", "partial_update", "me"]:
            return [IsAuthenticated()]
        return [IsStaffOrAbove()]

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        if self.action in ["update", "partial_update"]:
            user = request.user
            if is_management_staff(user):
                return
            if hasattr(user, "athlete") and user.athlete == obj:
                return
            if user.role == "parent" and ParentAthlete.objects.filter(parent=user, athlete=obj).exists():
                return
            self.permission_denied(request, message="ليس لديك صلاحية لتعديل بيانات هذا الرياضي")

    @transaction.atomic
    def perform_destroy(self, instance):
        # Delete user credentials to free up the phone number
        user = getattr(instance, "user_account", None)
        if user:
            user.delete()
        instance.delete()

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        password = request.data.get("password", None)
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        athlete = serializer.save()

        # Determine user role based on academy (Al Aws -> Parent, Al Ahli -> Athlete)
        target_role = User.Role.ATHLETE
        if athlete.department and ("أوس" in athlete.department.name_ar or "aws" in athlete.department.name.lower()):
            target_role = User.Role.PARENT

        first_name, last_name = _split_full_name(athlete.full_name)
        user, created = User.objects.get_or_create(
            phone=athlete.phone,
            defaults={
                "first_name_ar": first_name or athlete.full_name,
                "last_name_ar": last_name,
                "role": target_role,
                "residence": athlete.residence,
                "is_active": athlete.is_active,
            },
        )

        if created:
            user.set_password(password or secrets.token_urlsafe(16))
        elif password:
            user.set_password(password)

        if user.role != target_role:
            user.role = target_role

        user.first_name_ar = first_name or user.first_name_ar or athlete.full_name
        user.last_name_ar = last_name
        user.athlete = athlete
        user.is_active = athlete.is_active
        user.save()

        if target_role == User.Role.PARENT:
            ParentAthlete.objects.get_or_create(parent=user, athlete=athlete)

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
                {"active": False, "detail": "رقم العضوية غير موجود"},
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
    filterset_class = RegistrationRequestFilter

    def get_queryset(self):
        from django.db.models import Q

        from apps.accounts.permissions import is_super_admin
        user = self.request.user
        qs = RegistrationRequest.objects.all().select_related(
            "user", "reviewed_by", "athlete", "athlete__department"
        ).prefetch_related("athlete__parents__parent")
        if is_super_admin(user):
            return qs
        if user.academy:
            return qs.filter(
                Q(athlete__department=user.academy) |
                Q(athlete__isnull=True, user__academy=user.academy)
            )
        if getattr(user, "role", None) == "special_manager":
            dept_id = self.request.query_params.get("department")
            if dept_id:
                return qs.filter(
                    Q(athlete__department=dept_id) |
                    Q(athlete__isnull=True, role_choice=RegistrationRequest.RoleChoice.PARENT, user__academy=dept_id) |
                    Q(athlete__isnull=True, role_choice=RegistrationRequest.RoleChoice.PARENT, user__academy__isnull=True)
                )
        return qs


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
        registration.reviewed_at = timezone.now()
        registration.save()

        user = registration.user
        if user and not user.is_active:
            user.is_active = True
            user.save(update_fields=["is_active"])

        athlete = getattr(registration, "athlete", None)
        if athlete:
            subscription = athlete.subscriptions.filter(status=Subscription.Status.PENDING).first()
            if subscription:
                subscription.status = Subscription.Status.ACTIVE
                subscription.approved_by = request.user
                subscription.approved_at = timezone.now()
                subscription.save()
            athlete.is_active = True
            athlete.save(update_fields=["is_active"])

        return Response({"detail": "تم قبول طلب التسجيل", "registration_id": registration.id})

    @transaction.atomic
    @action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        registration = self.get_object()
        if registration.status != RegistrationRequest.Status.PENDING:
            return Response({"detail": "تمت معالجة طلب التسجيل بالفعل"}, status=status.HTTP_400_BAD_REQUEST)

        serializer = RegistrationRejectSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reason = serializer.validated_data["reason"]

        import logging
        logging.getLogger(__name__).info(
            "Account rejection: registration ID=%s, user=%s, reason=%s",
            registration.id, registration.user_id, reason,
        )

        registration.status = RegistrationRequest.Status.REJECTED
        registration.rejection_reason = reason
        registration.reviewed_by = request.user
        registration.reviewed_at = timezone.now()
        registration.save()

        try:
            from apps.notifications.services import send_admin_push_sync
            send_admin_push_sync(
                title="تم رفض طلب التسجيل",
                body=reason,
                notification_type="registration_rejected",
                entity_id=registration.id,
            )
        except Exception:
            logging.getLogger(__name__).exception("Failed to send push notification for registration rejection")

        return Response({"detail": "تم رفض طلب التسجيل", "registration_id": registration.id})


    @transaction.atomic
    @action(detail=True, methods=["patch"], url_path="parent-update")
    def parent_update(self, request, pk=None):
        registration = self.get_object()

        if registration.role_choice != RegistrationRequest.RoleChoice.PARENT:
            return Response(
                {"detail": "هذا الإجراء مخصص لتعديل بيانات أولياء الأمور فقط"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = ParentUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        user = registration.user
        update_fields = []

        if data.get("full_name") is not None and data["full_name"].strip():
            first_name, last_name = _split_full_name(data["full_name"])
            user.first_name_ar = first_name
            user.last_name_ar = last_name
            update_fields += ["first_name_ar", "last_name_ar"]

        if data.get("whatsapp_phone") is not None:
            phone = data["whatsapp_phone"]
            if phone and User.objects.filter(phone=phone).exclude(pk=user.pk).exists():
                return Response(
                    {"detail": {"whatsapp_phone": "رقم الهاتف هذا مسجل بالفعل"}},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            user.phone = phone
            user.whatsapp_phone = phone
            update_fields += ["phone", "whatsapp_phone"]

        if update_fields:
            user.save(update_fields=update_fields)

        if "residence" in data:
            registration.residence = data["residence"]
            registration.save(update_fields=["residence"])

        return Response(
            RegistrationRequestSerializer(registration, context={"request": request}).data
        )


class ParentAthleteViewSet(viewsets.ModelViewSet):
    serializer_class = ParentAthleteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return ParentAthlete.objects.filter(parent=self.request.user).select_related("athlete")

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        from apps.accounts.permissions import is_management_staff

        staff_mode = is_management_staff(request.user)
        parent_id = request.data.get("parent_id")

        if staff_mode and parent_id and str(parent_id).isdigit():
            parent = User.objects.filter(id=parent_id, role=User.Role.PARENT).first()
            if not parent:
                return Response({"detail": "ولي الأمر غير موجود"}, status=status.HTTP_400_BAD_REQUEST)
        else:
            parent = request.user

        athlete_id = request.data.get("athlete")
        if athlete_id and str(athlete_id).isdigit():
            if staff_mode and parent_id and str(parent_id).isdigit():
                existing = ParentAthlete.objects.filter(parent=parent, athlete_id=athlete_id).first()
                if existing:
                    return Response(ParentAthleteSerializer(existing).data)
            serializer = self.get_serializer(data={
                "athlete": athlete_id,
                "relationship": request.data.get("relationship", ""),
            })
            serializer.is_valid(raise_exception=True)
            link = serializer.save(parent=parent)
            return Response(ParentAthleteSerializer(link).data, status=status.HTTP_201_CREATED)

        full_name = request.data.get("full_name")
        phone = request.data.get("phone")
        photo_data = request.data.get("photo")
        birth_day = request.data.get("birth_day")
        birth_month = request.data.get("birth_month")
        birth_year = request.data.get("birth_year")
        health_status = request.data.get("health_status", "")

        if not full_name:
            return Response({"detail": "الاسم الكامل مطلوب"}, status=status.HTTP_400_BAD_REQUEST)

        if not phone:
            phone = f"child_{uuid.uuid4().hex[:10]}"
        else:
            phone = validate_libyan_phone(phone)
            if User.objects.filter(phone=phone).exists() or Athlete.objects.filter(phone=phone).exists():
                return Response({"detail": "رقم الهاتف مسجل بالفعل"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            birth_date = datetime.date(int(birth_year), int(birth_month), int(birth_day))
        except (ValueError, TypeError, OverflowError):
            return Response({"detail": "تاريخ الميلاد غير صالح"}, status=status.HTTP_400_BAD_REQUEST)

        photo_file = None
        if photo_data:
            try:
                img_format, imgstr = photo_data.split(";base64,")
                ext = img_format.split("/")[-1] if "/" in img_format else "jpg"
                photo_file = ContentFile(base64.b64decode(imgstr), name=f"{uuid.uuid4().hex}.{ext}")
            except (ValueError, IndexError, TypeError):
                return Response({"detail": "تنسيق الصورة غير صالح"}, status=status.HTTP_400_BAD_REQUEST)

        sport_id = request.data.get("sport") or parent.preferred_sport_id
        dept_id = request.data.get("department") or parent.academy_id
        if not dept_id:
            from apps.departments.models import Department
            dept = Department.objects.filter(name_ar__icontains="أوس").first() or Department.objects.order_by("id").first()
            dept_id = dept.id if dept else None

        user = User.objects.create_user(
            phone=phone,
            first_name_ar=full_name,
            last_name_ar="",
            password=secrets.token_urlsafe(16),
            role="athlete",
            residence=parent.residence,
            whatsapp_phone=parent.phone,
            is_active=staff_mode,
            academy_id=dept_id,
            preferred_sport_id=sport_id if parent_id else None,
        )
        registration = RegistrationRequest.objects.create(
            user=user,
            role_choice=RegistrationRequest.RoleChoice.ATHLETE,
            residence=parent.residence,
            health_status=health_status,
            status=RegistrationRequest.Status.APPROVED if staff_mode else RegistrationRequest.Status.PENDING,
            reviewed_by=request.user if staff_mode else None,
            reviewed_at=timezone.now() if staff_mode else None,
        )

        p_name = parent.full_name_ar or f"{parent.first_name_ar} {parent.last_name_ar}".strip()
        athlete = Athlete.objects.create(
            full_name=full_name,
            phone=phone,
            parent_name=p_name,
            parent_phone=parent.phone,
            birth_date=birth_date,
            gender="male",
            photo=photo_file,
            residence=parent.residence,
            health_status=health_status,
            notes="",
            is_active=staff_mode,
            registration=registration,
            department_id=dept_id,
            sport_id=sport_id,
        )
        user.athlete = athlete
        user.save(update_fields=["athlete"])

        parent_link = ParentAthlete.objects.create(parent=parent, athlete=athlete)
        return Response(ParentAthleteSerializer(parent_link).data, status=status.HTTP_201_CREATED)

    def perform_create(self, serializer):
        serializer.save(parent=self.request.user)

    @action(detail=False, methods=["get"])
    def children(self, request):
        athletes = Athlete.objects.filter(parents__parent=request.user)
        serializer = AthleteDetailSerializer(athletes, many=True, context={"request": request})
        return Response(serializer.data)

    @action(detail=False, methods=["get"])
    def children_of(self, request):
        from django.db.models import Q
        from apps.accounts.permissions import is_management_staff

        if not is_management_staff(request.user):
            return Response({"detail": "لا تملك صلاحية الوصول"}, status=status.HTTP_403_FORBIDDEN)

        parent_id = request.query_params.get("parent_id")
        parent = User.objects.filter(id=parent_id).first() if parent_id else None
        if not parent:
            return Response({"detail": "ولي الأمر غير موجود"}, status=status.HTTP_404_NOT_FOUND)

        dept_id = request.query_params.get("department")
        athletes = Athlete.objects.filter(
            Q(parents__parent=parent) | Q(parent_phone=parent.phone) | Q(registration__user=parent)
        ).select_related("department", "sport", "registration").distinct()

        if dept_id:
            athletes = athletes.filter(department_id=dept_id)
        serializer = AthleteDetailSerializer(athletes, many=True, context={"request": request})
        return Response(serializer.data)
