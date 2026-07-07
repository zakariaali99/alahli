from django.contrib.auth.backends import ModelBackend

from .models import User


class RejectedRegistrationBackend(ModelBackend):
    def user_can_authenticate(self, user):
        if not user.is_active:
            has_rejected = user.registration_requests.filter(
                status="rejected"
            ).exists()
            if has_rejected:
                return True
            return False
        return True
