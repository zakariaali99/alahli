from django.db import connection
from django.http import JsonResponse


def health_check(request):
    try:
        connection.ensure_connection()
        db_ok = True
    except Exception:
        db_ok = False

    return JsonResponse({
        "status": "healthy" if db_ok else "degraded",
        "database": "connected" if db_ok else "disconnected",
    })


def push_health_check(request):
    from django.conf import settings

    from apps.accounts.models import User
    from apps.notifications.models import Device

    verdict = {"firebase_configured": False, "admin_devices": 0, "push_sent": 0}
    cred_path = getattr(settings, "FCM_CREDENTIALS_PATH", "")
    verdict["fcm_credentials_path"] = cred_path or "(not set)"

    import os
    if cred_path and os.path.exists(cred_path):
        verdict["firebase_configured"] = True

    admin_roles = [User.Role.SUPER_ADMIN, User.Role.RECEPTION, "academy_manager"]
    tokens = list(
        Device.objects.filter(user__role__in=admin_roles, is_active=True)
        .values_list("fcm_token", flat=True)
    )
    verdict["admin_devices"] = len(tokens)

    if verdict["firebase_configured"] and tokens:
        from apps.notifications.services import FCMService
        count = FCMService.send_push(
            tokens[:1],
            "فحص النظام",
            "إشعار تجريبي من لوحة التحكم",
            data={"type": "health_check"},
        )
        verdict["push_sent"] = count

    status_code = 200 if verdict["firebase_configured"] else 503
    return JsonResponse(verdict, status=status_code)
