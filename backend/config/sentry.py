import os

import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration


def init_sentry():
    dsn = os.environ.get("SENTRY_DSN")
    if not dsn:
        return

    environment = "production" if os.environ.get("DJANGO_DEBUG", "False") != "True" else "development"

    sentry_sdk.init(
        dsn=dsn,
        environment=environment,
        integrations=[DjangoIntegration()],
        traces_sample_rate=float(os.environ.get("SENTRY_TRACES_SAMPLE_RATE", "0.1")),
        send_default_pii=False,
    )
