from datetime import timedelta

from django.contrib.auth import authenticate
from rest_framework import status, viewsets
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
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
from .permissions import IsReceptionOrAbove


class LoginRateThrottle(AnonRateThrottle):
    rate = "10/minute"


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by("-id")
    permission_classes = [IsReceptionOrAbove]
    filterset_fields = ["role"]
    search_fields = ["phone", "full_name_ar"]

    def get_serializer_class(self):
        if self.action == "create":
            return UserCreateSerializer
        if self.action in ["update", "partial_update"]:
            return UserUpdateSerializer
        return UserSerializer

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

    user = authenticate(
        username=serializer.validated_data["phone"],
        password=serializer.validated_data["password"],
    )

    if not user:
        return Response(
            {"detail": "Invalid phone number or password"},
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
def logout_view(request):
    refresh_token = request.data.get("refresh")
    if refresh_token:
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except Exception:
            return Response(
                {"detail": "Invalid or expired refresh token"},
                status=status.HTTP_400_BAD_REQUEST,
            )
    else:
        user = request.user
        for token in OutstandingToken.objects.filter(user=user):
            BlacklistedToken.objects.get_or_create(token=token)
    return Response({"detail": "Logged out successfully"})


@api_view(["GET"])
def me_view(request):
    user = User.objects.select_related("athlete__department").get(pk=request.user.pk)
    return Response(UserSerializer(user, context={"request": request}).data)


@api_view(["POST"])
def change_password_view(request):
    from django.contrib.auth.password_validation import validate_password
    from django.core.exceptions import ValidationError

    serializer = ChangePasswordSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    if not request.user.check_password(serializer.validated_data["old_password"]):
        return Response(
            {"old_password": "Wrong password"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    new_password = serializer.validated_data["new_password"]
    try:
        validate_password(new_password, user=request.user)
    except ValidationError as e:
        return Response({"new_password": list(e.messages)}, status=status.HTTP_400_BAD_REQUEST)

    request.user.set_password(new_password)
    request.user.save()

    for token in OutstandingToken.objects.filter(user=request.user):
        BlacklistedToken.objects.get_or_create(token=token)

    return Response({"detail": "Password changed successfully. Please log in again."})
