import os
import sys
from pathlib import Path

APP_DIR = Path(__file__).resolve().parent

sys.path.insert(0, str(APP_DIR / "backend"))

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.production")

os.environ.setdefault("DJANGO_SECRET_KEY", "change-me-in-production")

from django.core.wsgi import get_wsgi_application

application = get_wsgi_application()
