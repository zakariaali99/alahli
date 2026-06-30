from pathlib import Path

from django.conf import settings
from django.http import FileResponse, Http404, HttpResponseNotModified

FRONTEND_DIR = settings.BASE_DIR / "backend_static" / "frontend"

MIME_TYPES = {
    ".js": "application/javascript",
    ".css": "text/css",
    ".png": "image/png",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon",
    ".webp": "image/webp",
    ".woff2": "font/woff2",
    ".woff": "font/woff",
    ".json": "application/json",
    ".txt": "text/plain",
}


def serve_spa(request):
    index_path = FRONTEND_DIR / "index.html"
    if not index_path.exists():
        raise Http404("Frontend build not found. Run collectstatic.")
    stat = index_path.stat()
    etag = f'"{stat.st_mtime_ns:x}"'
    if request.META.get("HTTP_IF_NONE_MATCH") == etag:
        return HttpResponseNotModified()
    response = FileResponse(open(index_path, "rb"), content_type="text/html")
    response["ETag"] = etag
    response["Cache-Control"] = "public, max-age=0, must-revalidate"
    return response


def serve_frontend_assets(request, path):
    file_path = FRONTEND_DIR / path
    if not file_path.exists() or not file_path.is_file():
        raise Http404()
    content_type = MIME_TYPES.get(file_path.suffix, "application/octet-stream")
    response = FileResponse(open(file_path, "rb"), content_type=content_type)
    response["Cache-Control"] = "public, max-age=31536000, immutable"
    return response


def serve_media(request, path):
    file_path = settings.MEDIA_ROOT / path
    if not file_path.exists() or not file_path.is_file():
        raise Http404()
    content_type = MIME_TYPES.get(file_path.suffix, "application/octet-stream")
    response = FileResponse(open(file_path, "rb"), content_type=content_type)
    response["Cache-Control"] = "public, max-age=86400"
    return response
