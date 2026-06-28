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
