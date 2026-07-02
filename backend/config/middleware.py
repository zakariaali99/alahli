import logging
import uuid

from django.http import JsonResponse

logger = logging.getLogger(__name__)


class RequestIDMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request_id = str(uuid.uuid4())
        request.request_id = request_id
        response = self.get_response(request)
        response["X-Request-ID"] = request_id
        return response


class ErrorCaptureMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        try:
            response = self.get_response(request)
        except Exception as exc:
            request_id = getattr(request, "request_id", None)
            logger.exception(
                "Unhandled error [request_id=%s] %s %s",
                request_id,
                request.method,
                request.path,
            )
            return JsonResponse(
                {
                    "error": True,
                    "code": "SERVER_ERROR",
                    "detail": {"server": "Internal server error"},
                    "status_code": 500,
                    "request_id": request_id,
                },
                status=500,
            )
        return response
