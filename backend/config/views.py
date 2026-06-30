from pathlib import Path

from django.conf import settings
from django.http import FileResponse, Http404

FRONTEND_DIR = settings.BASE_DIR / "frontend_build"

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
    return FileResponse(open(index_path, "rb"), content_type="text/html")


def serve_frontend_assets(request, path):
    file_path = FRONTEND_DIR / path
    if not file_path.exists() or not file_path.is_file():
        raise Http404()
    content_type = MIME_TYPES.get(file_path.suffix, "application/octet-stream")
    return FileResponse(open(file_path, "rb"), content_type=content_type)
