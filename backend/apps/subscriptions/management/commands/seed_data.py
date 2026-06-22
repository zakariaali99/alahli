from datetime import date, timedelta

from dateutil.relativedelta import relativedelta
from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.accounts.models import User
from apps.athletes.models import Athlete
from apps.departments.models import Department
from apps.subscriptions.models import Renewal, Subscription

DEPARTMENTS = [
    {"name": "Al Ahly Sports Center", "name_ar": "مركز الأهلي الرياضي", "color": "#1487D4"},
    {"name": "AWS Football Academy", "name_ar": "أكاديمية AWS لكرة القدم", "color": "#1E7A43"},
]

ATHLETES = [
    {"full_name": "أحمد محمد عبدالله", "phone": "0912345671", "birth_date": "2000-05-15", "gender": "male", "dept_idx": 0},
    {"full_name": "سارة أحمد علي", "phone": "0912345672", "birth_date": "1998-08-22", "gender": "female", "dept_idx": 0},
    {"full_name": "محمد خالد سعيد", "phone": "0912345673", "birth_date": "2002-01-10", "gender": "male", "dept_idx": 1},
    {"full_name": "فاطمة عمر حسن", "phone": "0912345674", "birth_date": "2001-11-03", "gender": "female", "dept_idx": 1},
    {"full_name": "عمر عبدالله سالم", "phone": "0912345675", "birth_date": "1999-03-28", "gender": "male", "dept_idx": 0},
    {"full_name": "نورة علي محمد", "phone": "0912345676", "birth_date": "2003-07-14", "gender": "female", "dept_idx": 1},
    {"full_name": "خالد سعيد إبراهيم", "phone": "0912345677", "birth_date": "1997-12-01", "gender": "male", "dept_idx": 0},
    {"full_name": "مريم عبدالرحمن أحمد", "phone": "0912345678", "birth_date": "2004-04-19", "gender": "female", "dept_idx": 0},
    {"full_name": "يوسف محمد يوسف", "phone": "0912345679", "birth_date": "1996-09-08", "gender": "male", "dept_idx": 1},
    {"full_name": "هدى خالد عبدالله", "phone": "0912345680", "birth_date": "2000-06-25", "gender": "female", "dept_idx": 1},
    {"full_name": "علي حسن علي", "phone": "0912345681", "birth_date": "1995-02-17", "gender": "male", "dept_idx": 0},
    {"full_name": "رنا عمر سعيد", "phone": "0912345682", "birth_date": "2002-10-30", "gender": "female", "dept_idx": 0},
    {"full_name": "عبدالله محمد أحمد", "phone": "0912345683", "birth_date": "1998-07-05", "gender": "male", "dept_idx": 1},
    {"full_name": "سلمى خالد عمر", "phone": "0912345684", "birth_date": "2001-01-20", "gender": "female", "dept_idx": 1},
    {"full_name": "إبراهيم علي حسن", "phone": "0912345685", "birth_date": "1999-04-12", "gender": "male", "dept_idx": 0},
    {"full_name": "ناديا محمد خالد", "phone": "0912345686", "birth_date": "2003-08-08", "gender": "female", "dept_idx": 0},
    {"full_name": "حسن عمر حسن", "phone": "0912345687", "birth_date": "1997-11-22", "gender": "male", "dept_idx": 1},
    {"full_name": "ليلى أحمد محمد", "phone": "0912345688", "birth_date": "2000-03-15", "gender": "female", "dept_idx": 1},
    {"full_name": "موسى خالد سليم", "phone": "0912345689", "birth_date": "1996-06-30", "gender": "male", "dept_idx": 0},
    {"full_name": "دينا عمر علي", "phone": "0912345690", "birth_date": "2004-12-05", "gender": "female", "dept_idx": 0},
]


class Command(BaseCommand):
    help = "Seed initial data for development"

    def handle(self, *args, **kwargs):
        self.stdout.write("Seeding data...")

        if not User.objects.filter(phone="0910000000").exists():
            User.objects.create_superuser(
                phone="0910000000",
                first_name_ar="مشرف",
                last_name_ar="النظام",
                password="admin123",
                role="super_admin",
            )
            self.stdout.write("  Created super admin: 0910000000 / admin123")

        if not User.objects.filter(phone="0910000001").exists():
            User.objects.create_user(
                phone="0910000001",
                first_name_ar="استقبال",
                last_name_ar="النادي",
                password="recep123",
                role="reception",
            )
            self.stdout.write("  Created reception user: 0910000001 / recep123")

        departments = []
        for dept_data in DEPARTMENTS:
            dept, created = Department.objects.get_or_create(
                name=dept_data["name"],
                defaults=dept_data,
            )
            if created:
                departments.append(dept)
                self.stdout.write(f"  Created department: {dept.name_ar}")
            else:
                departments.append(dept)

        for athlete_data in ATHLETES:
            dept = departments[athlete_data["dept_idx"]]
            athlete, created = Athlete.objects.get_or_create(
                phone=athlete_data["phone"],
                defaults={
                    "full_name": athlete_data["full_name"],
                    "birth_date": athlete_data["birth_date"],
                    "gender": athlete_data["gender"],
                    "department": dept,
                    "parent_phone": "",
                },
            )
            if created:
                self.stdout.write(f"  Created athlete: {athlete.full_name}")

                today = date.today()
                start = today - timedelta(days=60)
                end = start + relativedelta(months=6)

                sub = Subscription.objects.create(
                    athlete=athlete,
                    start_date=start,
                    end_date=end,
                    amount=250.00,
                    status=Subscription.Status.ACTIVE,
                )

                Renewal.objects.create(
                    subscription=sub,
                    amount=250.00,
                    months=6,
                    renewal_date=start,
                )

        self.stdout.write(self.style.SUCCESS("Seeding complete!"))
