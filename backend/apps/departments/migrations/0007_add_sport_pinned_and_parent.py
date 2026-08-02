from django.db import migrations, models

def pin_and_enable_parents(apps, schema_editor):
    Department = apps.get_model("departments", "Department")
    Sport = apps.get_model("departments", "Sport")

    for dept in Department.objects.all():
        name_norm = (dept.name_ar or "").replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").lower()
        if "اوس" in name_norm or "aws" in (dept.name or "").lower():
            # AWS Academy: Only Football
            Sport.objects.filter(department=dept).filter(name_ar__icontains="كاراتيه").delete()
            Sport.objects.filter(department=dept).filter(name_ar__icontains="سويدي").delete()
            Sport.objects.filter(department=dept).filter(name_ar__icontains="لياقة").delete()

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
                fb.save()
        else:
            # Al-Ahly Sports Center: Karate and Fitness
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
                fitness.save()

class Migration(migrations.Migration):

    dependencies = [
        ("departments", "0006_alter_department_options_brand_colors"),
    ]

    operations = [
        migrations.AlterModelOptions(
            name="sport",
            options={"ordering": ["-is_pinned", "name_ar"]},
        ),
        migrations.AddField(
            model_name="sport",
            name="is_pinned",
            field=models.BooleanField(default=False, help_text="تثبيت الرياضة في أعلى القائمة"),
        ),
        migrations.AddField(
            model_name="sport",
            name="supports_parents",
            field=models.BooleanField(default=False, help_text="تمكين نظام أولياء الأمور لهذه الرياضة"),
        ),
        migrations.RunPython(pin_and_enable_parents, reverse_code=migrations.RunPython.noop),
    ]
