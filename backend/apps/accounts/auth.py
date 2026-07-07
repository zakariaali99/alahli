from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import AuthenticationFailed, InvalidToken
from rest_framework_simplejwt.settings import api_settings


class RejectedRegistrationAwareJWTAuth(JWTAuthentication):
    def get_user(self, validated_token):
        try:
            user_id = validated_token[api_settings.USER_ID_CLAIM]
        except KeyError:
            raise InvalidToken("Token contained no recognizable user identification")

        from .models import User

        try:
            user = User.objects.get(**{api_settings.USER_ID_FIELD: user_id})
        except User.DoesNotExist:
            raise AuthenticationFailed("المستخدم غير موجود", code="user_not_found")

        if not user.is_active:
            has_rejected = user.registration_requests.filter(status="rejected").exists()
            if not has_rejected:
                raise AuthenticationFailed("تم تعطيل هذا الحساب", code="user_inactive")

        return user
