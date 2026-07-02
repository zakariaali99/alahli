import logging

from rest_framework import status
from rest_framework.exceptions import (
    APIException,
    AuthenticationFailed,
    NotAuthenticated,
    NotFound,
    PermissionDenied,
    Throttled,
    ValidationError,
)
from rest_framework.views import exception_handler

logger = logging.getLogger(__name__)

ERROR_CODES = {
    ValidationError: "VALIDATION_ERROR",
    AuthenticationFailed: "AUTHENTICATION_FAILED",
    NotAuthenticated: "NOT_AUTHENTICATED",
    PermissionDenied: "PERMISSION_DENIED",
    NotFound: "NOT_FOUND",
    Throttled: "RATE_LIMITED",
}


def get_error_code(exc):
    for exc_type, code in ERROR_CODES.items():
        if isinstance(exc, exc_type):
            return code
    return "SERVER_ERROR"


def custom_exception_handler(exc, context):
    request = context.get("request")
    request_id = getattr(request, "request_id", None)
    view = context.get("view")

    response = exception_handler(exc, context)

    if response is not None:
        detail = response.data

        errors = {}
        if isinstance(detail, dict):
            for key, value in detail.items():
                if isinstance(value, list):
                    messages = [str(item) for item in value]
                    errors[key] = messages[0] if len(messages) == 1 else messages
                else:
                    errors[key] = str(value)
        elif isinstance(detail, list):
            errors = {"detail": [str(item) for item in detail]}
            detail = errors["detail"]
        else:
            errors = {"detail": str(detail) if detail else "Unknown error"}

        response.data = {
            "error": True,
            "code": get_error_code(exc),
            "detail": errors,
            "status_code": response.status_code,
        }
        if request_id:
            response.data["request_id"] = request_id
    else:
        logger.exception(
            "Unhandled exception in %s: %s",
            view.__class__.__name__ if view else "unknown",
            exc,
        )
        response_data = {
            "error": True,
            "code": "SERVER_ERROR",
            "detail": {"server": "Internal server error"},
            "status_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
        }
        if request_id:
            response_data["request_id"] = request_id
        from rest_framework.response import Response

        response = Response(response_data, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return response
