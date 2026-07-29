from datetime import timedelta

from django.contrib.auth import authenticate
from rest_framework import status, viewsets
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken
from rest_framework_simplejwt.tokens import OutstandingToken, RefreshToken

from .models import User
from .serializers import (
    ChangePasswordSerializer,
    LoginSerializer,
    UserSerializer,
    UserCreateSerializer,
    UserUpdateSerializer,
)
from .permissions import IsRejectedAccount, IsStaffOrAbove, IsSuperAdmin, scope_by_academy


class LoginRateThrottle(AnonRateThrottle):
    rate = "1000/minute"


class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    filterset_fields = ["role"]
    search_fields = ["phone", "full_name_ar"]

    def get_queryset(self):
        qs = User.objects.filter(
            role__in=["super_admin", "reception", "academy_manager", "special_manager", "trainer", "viewer"]
        ).order_by("-id")
        return scope_by_academy(self.request.user, qs, academy_field="academy")

    def get_serializer_class(self):
        if self.action == "create":
            return UserCreateSerializer
        if self.action in ["update", "partial_update"]:
            return UserUpdateSerializer
        return UserSerializer

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsSuperAdmin()]
        return [IsStaffOrAbove()]

    def create(self, request, *args, **kwargs):
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial, context={"request": request})
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data)

    def perform_update(self, serializer):
        serializer.save()


@api_view(["POST"])
@permission_classes([AllowAny])
@throttle_classes([LoginRateThrottle])
def login_view(request):
    serializer = LoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    phone = serializer.validated_data["phone"]
    password = serializer.validated_data.get("password", "")

    existing_user = User.objects.filter(phone=phone).first()
    if not existing_user:
        return Response(
            {"detail": "رقم الهاتف هذا غير مسجل بالنظام"},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if not existing_user.is_active:
        has_rejected = existing_user.registration_requests.filter(status="rejected").exists()
        if not has_rejected:
            return Response(
                {"detail": "حسابك قيد المراجعة حالياً ولا يمكن تسجيل الدخول حتى تتم الموافقة على طلب التسجيل"},
                status=status.HTTP_401_UNAUTHORIZED,
            )

    # Phone-only login for client users (athletes and parents)
    if existing_user.role in ["athlete", "parent"]:
        user = existing_user
    else:
        # Require password for staff and management accounts
        if not password:
            return Response(
                {"detail": "كلمة المرور مطلوبة لحسابات الإدارة والموظفين"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user = authenticate(username=phone, password=password)
        if not user:
            return Response(
                {"detail": "رقم الهاتف أو كلمة المرور غير صحيحة"},
                status=status.HTTP_401_UNAUTHORIZED,
            )

    user = User.objects.select_related("athlete__department").get(pk=user.pk)
    refresh = RefreshToken.for_user(user)
    if serializer.validated_data.get("remember_me"):
        refresh.set_exp(lifetime=timedelta(days=30))
    return Response({
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "user": UserSerializer(user, context={"request": request}).data,
        "remember_me": serializer.validated_data.get("remember_me", False),
    })


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def logout_view(request):
    refresh_token = request.data.get("refresh")
    if refresh_token:
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except TokenError:
            return Response(
                {"detail": "رمز التحديث غير صالح أو منتهي الصلاحية"},
                status=status.HTTP_400_BAD_REQUEST,
            )
    else:
        user = request.user
        for token in OutstandingToken.objects.filter(user=user):
            BlacklistedToken.objects.get_or_create(token=token)
    return Response({"detail": "تم تسجيل الخروج بنجاح"})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def me_view(request):
    user = User.objects.select_related("athlete__department").get(pk=request.user.pk)
    return Response(UserSerializer(user, context={"request": request}).data)


@api_view(["PATCH", "PUT"])
@permission_classes([IsAuthenticated])
def update_profile_view(request):
    user = request.user
    serializer = UserProfileUpdateSerializer(user, data=request.data, partial=True, context={"request": request})
    serializer.is_valid(raise_exception=True)
    serializer.save()

    # Also update residence on linked athlete if user is an athlete
    if hasattr(user, "athlete") and user.athlete:
        if "residence" in request.data:
            user.athlete.residence = request.data["residence"]
        if "first_name_ar" in request.data:
            user.athlete.full_name = request.data["first_name_ar"]
        user.athlete.save()

    # Also update residence on child athletes if user is a parent
    if user.role == "parent" and "residence" in request.data:
        from apps.athletes.models import ParentAthlete
        linked_athlete_ids = ParentAthlete.objects.filter(parent=user).values_list("athlete_id", flat=True)
        from apps.athletes.models import Athlete
        Athlete.objects.filter(id__in=linked_athlete_ids).update(residence=request.data["residence"])

    updated_user = User.objects.select_related("athlete__department").get(pk=user.pk)
    return Response(UserSerializer(updated_user, context={"request": request}).data)


@api_view(["POST"])
def change_password_view(request):
    serializer = ChangePasswordSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    if not request.user.check_password(serializer.validated_data["old_password"]):
        return Response(
            {"old_password": "كلمة المرور الحالية غير صحيحة"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    request.user.set_password(serializer.validated_data["new_password"])
    request.user.save()

    for token in OutstandingToken.objects.filter(user=request.user):
        BlacklistedToken.objects.get_or_create(token=token)

    return Response({"detail": "تم تغيير كلمة المرور بنجاح. يرجى تسجيل الدخول مرة أخرى."})


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsRejectedAccount])
def delete_rejected_account_view(request):
    from django.db import transaction

    user = request.user
    latest_registration = user.registration_requests.filter(status="rejected").order_by("-created_at").first()

    if not latest_registration:
        return Response(
            {"detail": "لم يتم العثور على طلب تسجيل مرفوض"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    from apps.athletes.models import Athlete, ParentAthlete

    with transaction.atomic():
        athlete = getattr(latest_registration, "athlete", None)
        if athlete and not athlete.is_active:
            athlete.delete()

        if user.role == "parent":
            ParentAthlete.objects.filter(parent=user).delete()

        latest_registration.delete()
        user.delete()

    return Response({"detail": "تم حذف الحساب بنجاح. يمكنك التسجيل من جديد."})
