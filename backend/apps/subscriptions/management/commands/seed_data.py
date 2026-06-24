from datetime import date, timedelta
from decimal import Decimal

from dateutil.relativedelta import relativedelta
from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.accounts.models import User
from apps.athletes.models import Athlete
from apps.departments.models import Department
from apps.subscriptions.models import Renewal, Subscription
from apps.trainers.models import Trainer, TrainerClass
from apps.workouts.models import (
    Booking,
    Exercise,
    ExerciseEquipment,
    ExerciseMovement,
    SessionCategory,
    WorkoutSession,
)
from apps.store.models import Product, ProductCategory
from apps.progress.models import Achievement, DailyStat, WeeklyProgress

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

        for i, athlete_data in enumerate(ATHLETES):
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

                if i == 0:
                    package = "الباقة الذهبية"
                    amount = Decimal("500.00")
                    start = today - timedelta(days=90)
                    end = start + relativedelta(years=1)
                    status = Subscription.Status.ACTIVE
                elif i <= 5:
                    package = "الباقة الأساسية"
                    amount = Decimal("250.00")
                    start = today - timedelta(days=60)
                    end = start + relativedelta(months=6)
                    status = Subscription.Status.ACTIVE
                elif i <= 10:
                    package = "الباقة الفضية"
                    amount = Decimal("350.00")
                    start = today - timedelta(days=300)
                    end = start + relativedelta(months=6)
                    status = Subscription.Status.EXPIRED
                elif i <= 15:
                    package = "الباقة الأساسية"
                    amount = Decimal("300.00")
                    start = today + timedelta(days=30)
                    end = start + relativedelta(months=6)
                    status = Subscription.Status.PENDING
                else:
                    package = "الباقة الذهبية"
                    amount = Decimal("500.00")
                    start = today - timedelta(days=45)
                    end = start + relativedelta(months=12)
                    status = Subscription.Status.ACTIVE

                sub = Subscription.objects.create(
                    athlete=athlete,
                    package_name=package,
                    start_date=start,
                    end_date=end,
                    amount=amount,
                    status=status,
                )

                Renewal.objects.create(
                    subscription=sub,
                    amount=amount,
                    months=6,
                    renewal_date=start,
                )

        admin = User.objects.filter(phone="0910000000").first()
        first_athlete = Athlete.objects.order_by("id").first()
        if admin and first_athlete and admin.athlete != first_athlete:
            admin.athlete = first_athlete
            admin.save()
            self.stdout.write(f"  Linked admin to athlete: {first_athlete.full_name}")

        self._seed_trainers()
        self._seed_workouts()
        self._seed_store()
        self._seed_progress()

        self.stdout.write(self.style.SUCCESS("Seeding complete!"))

    def _seed_workouts(self):
        cat_cardio, _ = SessionCategory.objects.get_or_create(
            slug="cardio", defaults={"display_ar": "تمارين كارديو"}
        )
        cat_strength, _ = SessionCategory.objects.get_or_create(
            slug="strength", defaults={"display_ar": "تمارين قوة"}
        )

        trainer = Trainer.objects.first()
        if not WorkoutSession.objects.exists() and trainer:
            sessions_data = [
                {"name": "تمارين صباحية", "category": cat_cardio, "date": date.today(), "time": "08:00", "duration_minutes": 45, "location": "الصالة الرئيسية", "trainer": trainer},
                {"name": "تمارين مسائية", "category": cat_strength, "date": date.today(), "time": "17:00", "duration_minutes": 60, "location": "صالة الحديد", "trainer": trainer},
            ]
            for s in sessions_data:
                ws = WorkoutSession.objects.create(**s)
                self.stdout.write(f"  Created session: {ws.name}")

        if not Exercise.objects.exists():
            ex1 = Exercise.objects.create(title="الضغط", description="تمرين الضغط الكلاسيكي", calories=80, duration_minutes=10, difficulty="beginner")
            ex2 = Exercise.objects.create(title="القرفصاء", description="تمرين القرفصاء الصحيح", calories=120, duration_minutes=15, difficulty="intermediate")
            ex3 = Exercise.objects.create(title="البلانك", description="تمرين البلانك لتقوية الجذع", calories=60, duration_minutes=5, difficulty="beginner")
            for ex in [ex1, ex2, ex3]:
                self.stdout.write(f"  Created exercise: {ex.title}")

            moves = [
                (ex1, "ضغط", 3, 12, 1),
                (ex1, "ضغط مائل", 3, 10, 2),
                (ex2, "قرفصاء", 4, 15, 1),
                (ex2, "قرفصاء مع دمبل", 3, 12, 2),
                (ex3, "بلانك ثابت", 3, 1, 1),
                (ex3, "بلانك جانبي", 2, 1, 2),
            ]
            for ex, name, sets, reps, order in moves:
                ExerciseMovement.objects.create(exercise=ex, name=name, sets=sets, reps=reps, order=order)

            equip = [
                (ex1, "لا يوجد"),
                (ex2, "دمبل"),
                (ex3, "سجادة"),
            ]
            for ex, name in equip:
                ExerciseEquipment.objects.create(exercise=ex, name=name)

    def _seed_trainers(self):
        if Trainer.objects.exists():
            return

        t1 = Trainer.objects.create(
            full_name_ar="أحمد علي", initials="أع", role="مدرب لياقة بدنية",
            bio="مدرب معتمد بخبرة 8 سنوات", rating=Decimal("4.8"),
            reviews_count=124, experience_years=8,
            profile_image="https://i.pravatar.cc/150?img=1",
        )
        t2 = Trainer.objects.create(
            full_name_ar="سارة محمد", initials="سم", role="مدربة تمارين نسائية",
            bio="أخصائية تمارين وتغذية", rating=Decimal("4.9"),
            reviews_count=98, experience_years=6,
            profile_image="https://i.pravatar.cc/150?img=5",
        )
        self.stdout.write(f"  Created trainers: {t1.full_name_ar}, {t2.full_name_ar}")

        classes_data = [
            (t1, "تمارين القوة", "متقدم", "برنامج شامل لبناء العضلات", Decimal("150"), 60),
            (t1, "تمارين الإحماء", "مبتدئ", "جلسة إحماء وتحرك", Decimal("80"), 30),
            (t2, "تمارين نسائية", "متوسط", "برنامج خاص للسيدات", Decimal("120"), 45),
        ]
        for trainer, title, intensity, desc, price, dur in classes_data:
            TrainerClass.objects.create(
                trainer=trainer, title=title, intensity=intensity,
                description=desc, price=price, currency="LYD", duration_minutes=dur,
            )
            self.stdout.write(f"  Created class: {title}")

    def _seed_store(self):
        cat_equip, _ = ProductCategory.objects.get_or_create(
            slug="equipment", defaults={"display_ar": "معدات رياضية"}
        )
        cat_nutrition, _ = ProductCategory.objects.get_or_create(
            slug="nutrition", defaults={"display_ar": "مكملات غذائية"}
        )

        if Product.objects.exists():
            return

        products_data = [
            ("حبل مقاومة", "حبل مقاومة مطاطي للتمارين", cat_equip, Decimal("45"), None, True, True),
            ("دمبل 5 كجم", "دمبل حديدي بوزن 5 كجم", cat_equip, Decimal("120"), Decimal("150"), True, False),
            ("بروتين واي", "بروتين مصل اللبن 2 كجم", cat_nutrition, Decimal("280"), Decimal("350"), False, True),
            ("ماء جوز الهند", "مشروب طاقة طبيعي 500مل", cat_nutrition, Decimal("15"), None, True, True),
        ]
        for name, desc, cat, price, orig, is_new, in_stock in products_data:
            Product.objects.create(
                name=name, description=desc, category=cat,
                price=price, currency="LYD", original_price=orig,
                is_new=is_new, in_stock=in_stock,
            )
            self.stdout.write(f"  Created product: {name}")

    def _seed_progress(self):
        user = User.objects.first()
        if not user:
            return

        if not WeeklyProgress.objects.exists():
            today = date.today()
            monday = today - timedelta(days=today.weekday())
            wp = WeeklyProgress.objects.create(
                user=user, week_start=monday, sessions_count=5,
                active_minutes=350, goal_progress=0.7, goal_target=420,
            )
            days = [
                ("السبت", "Saturday", 60, 1.0),
                ("الأحد", "Sunday", 45, 0.75),
                ("الإثنين", "Monday", 0, 0.0),
                ("الثلاثاء", "Tuesday", 75, 1.25),
                ("الأربعاء", "Wednesday", 50, 0.83),
                ("الخميس", "Thursday", 60, 1.0),
                ("الجمعة", "Friday", 60, 1.0),
            ]
            for abbr, full, value, hours in days:
                DailyStat.objects.create(
                    weekly_progress=wp, day_abbr=abbr, day_full=full,
                    value=float(value), hours=float(hours),
                )
            self.stdout.write("  Created weekly progress + daily stats")

        if not Achievement.objects.exists():
            achievements_data = [
                ("🏆", "أول تمرين", "أكمل أول تمرين في النادي", True, False),
                ("🔥", "5 أيام متتالية", "حافظ على التمرين 5 أيام متتالية", True, False),
                ("💪", "10 ساعات تدريب", "أكمل 10 ساعات تدريب", False, False),
                ("⭐", "المثابرة", "أكمل 30 يوم تدريب", False, True),
            ]
            for icon, title, subtitle, completed, locked in achievements_data:
                Achievement.objects.create(
                    user=user, icon=icon, title=title, subtitle=subtitle,
                    is_completed=completed, is_locked=locked,
                )
            self.stdout.write("  Created achievements")
