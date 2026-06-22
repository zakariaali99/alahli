from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import ChangePasswordSerializer, LoginSerializer, UserSerializer


@api_view(["POST"])
@permission_classes([AllowAny])
def login_view(request):
    serializer = LoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    from django.contrib.auth import authenticate
    user = authenticate(
        username=serializer.validated_data["phone"],
        password=serializer.validated_data["password"],
    )

    if not user:
        return Response(
            {"detail": "Invalid phone number or password"},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    refresh = RefreshToken.for_user(user)
    return Response({
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "user": UserSerializer(user).data,
    })


@api_view(["POST"])
def logout_view(request):
    try:
        refresh_token = request.data.get("refresh")
        if refresh_token:
            token = RefreshToken(refresh_token)
            token.blacklist()
        return Response({"detail": "Logged out successfully"})
    except Exception:
        return Response({"detail": "Invalid token"}, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"])
def me_view(request):
    return Response(UserSerializer(request.user).data)


@api_view(["POST"])
def change_password_view(request):
    serializer = ChangePasswordSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    if not request.user.check_password(serializer.validated_data["old_password"]):
        return Response(
            {"old_password": "Wrong password"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    request.user.set_password(serializer.validated_data["new_password"])
    request.user.save()
    return Response({"detail": "Password changed successfully"})
