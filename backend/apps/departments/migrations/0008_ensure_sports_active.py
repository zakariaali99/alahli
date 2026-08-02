from django.db import migrations

def ensure_sports_active(apps, schema_editor):
    Department = apps.get_model("departments", "Department")
    Sport = apps.get_model("departments", "Sport")

    # 1. Make sure all existing sports are marked is_active=True
    Sport.objects.all().update(is_active=True)

    # 2. Make sure every department has appropriate active sports
    for dept in Department.objects.all():
        name_norm = (dept.name_ar or "").replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").lower()
        is_aws = "اوس" in name_norm or "aws" in (dept.name or "").lower()

        if is_aws:
            fb = Sport.objects.filter(department=dept, name_ar__icontains="قدم").first()
            if not fb:
                Sport.objects.create(
                    department=dept,
                    name="Football",
                    name_ar="كرة قدم",
                    is_pinned=True,
                    supports_parents=True,
                    is_active=True,
                )
            else:
                fb.is_pinned = True
                fb.supports_parents = True
                fb.is_active = True
                fb.save()
        else:
            # Al-Ahly Sports Center
            karate = Sport.objects.filter(department=dept, name_ar__icontains="كاراتيه").first()
            if not karate:
                Sport.objects.create(
                    department=dept,
                    name="Karate",
                    name_ar="كاراتيه",
                    is_pinned=True,
                    supports_parents=True,
                    is_active=True,
                )
            else:
                karate.is_pinned = True
                karate.supports_parents = True
                karate.is_active = True
                karate.save()

            fitness = Sport.objects.filter(department=dept, name_ar__icontains="لياقة").first()
            if not fitness:
                fitness = Sport.objects.filter(department=dept, name_ar__icontains="سويدي").first()
            if not fitness:
                Sport.objects.create(
                    department=dept,
                    name="Fitness & Cardio",
                    name_ar="لياقة بدنية / سويدي",
                    is_pinned=True,
                    supports_parents=False,
                    is_active=True,
                )
            else:
                fitness.is_pinned = True
                fitness.is_active = True
                fitness.save()

class Migration(migrations.Migration):

    dependencies = [
        ("departments", "0007_add_sport_pinned_and_parent"),
    ]

    operations = [
        migrations.RunPython(ensure_sports_active, reverse_code=migrations.RunPython.noop),
    ]
