from django.core.management.base import BaseCommand
from django.db import transaction

from apps.athletes.models import RegistrationRequest


class Command(BaseCommand):
    help = "حذف طلبات التسجيل المرفوضة والمستخدمين المرتبطين بها"

    def handle(self, *args, **options):
        rejected = RegistrationRequest.objects.filter(status=RegistrationRequest.Status.REJECTED)
        count = rejected.count()
        self.stdout.write(f"Found {count} rejected registrations to clean up...")

        deleted_users = 0
        for reg in rejected:
            with transaction.atomic():
                user = reg.user
                reg.delete()
                if user and user.role in ["athlete", "parent"]:
                    user.delete()
                    deleted_users += 1

        self.stdout.write(self.style.SUCCESS(
            f"Cleaned up {count} rejected registrations and {deleted_users} associated users."
        ))
