from django.core.management.base import BaseCommand
from apps.accounts.models import User
from apps.athletes.models import Athlete


def normalize_phone(p: str) -> str:
    return "".join(ch for ch in (p or "") if ch.isdigit())


class Command(BaseCommand):
    help = "Link users with role=athlete to their Athlete profile if missing."

    def handle(self, *args, **options):
        fixed = 0
        still_missing = 0

        qs = User.objects.filter(role=User.Role.ATHLETE, athlete__isnull=True)
        for user in qs:
            athlete = None

            reg = user.registration_requests.select_related("athlete").order_by("-created_at").first()
            if reg and hasattr(reg, "athlete") and reg.athlete:
                athlete = reg.athlete

            if not athlete:
                athlete = Athlete.objects.filter(phone=user.phone).first()

            if not athlete:
                norm = normalize_phone(user.phone)
                if norm:
                    for cand in Athlete.objects.only("id", "phone").iterator():
                        if normalize_phone(cand.phone) == norm:
                            athlete = cand
                            break

            if athlete:
                user.athlete = athlete
                user.role = User.Role.ATHLETE
                user.save(update_fields=["athlete", "role"])
                fixed += 1
                self.stdout.write(f"  linked user {user.phone} -> athlete #{athlete.id}")
            else:
                still_missing += 1

        self.stdout.write(f"\nDone: {fixed} linked, {still_missing} still missing athlete profiles")
