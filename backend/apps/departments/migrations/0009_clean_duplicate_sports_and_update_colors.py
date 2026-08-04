from django.db import migrations, models

def clean_duplicates_and_update_colors(apps, schema_editor):
    Department = apps.get_model("departments", "Department")
    Sport = apps.get_model("departments", "Sport")
    Group = apps.get_model("departments", "Group")

    for dept in Department.objects.all():
        name_norm = (dept.name_ar or "").replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").replace("ة", "ه").lower()
        is_aws = "اوس" in name_norm or "aws" in (dept.name or "").lower()

        if is_aws:
            dept.color = "#136F63"
            dept.name_ar = "أكاديمية الأوس"
            dept.save()
        else:
            dept.color = "#0F4C81"
            dept.name_ar = "مركز الأهلي الرياضي"
            dept.save()

        # Deduplicate Karate sports for this department
        karate_sports = list(
            Sport.objects.filter(department=dept).filter(
                models.Q(name_ar__icontains="كارات") | models.Q(name__icontains="karate")
            ).order_by("id")
        )
        if len(karate_sports) > 1:
            primary_karate = karate_sports[0]
            primary_karate.name = "Karate"
            primary_karate.name_ar = "كاراتيه"
            primary_karate.is_pinned = True
            primary_karate.supports_parents = True
            primary_karate.is_active = True
            primary_karate.save()

            for dup in karate_sports[1:]:
                Group.objects.filter(sport=dup).update(sport=primary_karate)
                dup.delete()
        elif len(karate_sports) == 1:
            k = karate_sports[0]
            k.name = "Karate"
            k.name_ar = "كاراتيه"
            k.is_pinned = True
            k.supports_parents = True
            k.is_active = True
            k.save()

        # Deduplicate Fitness / Cardio sports for this department
        fitness_sports = list(
            Sport.objects.filter(department=dept).filter(
                models.Q(name_ar__icontains="لياقة") | models.Q(name_ar__icontains="سويدي") | models.Q(name__icontains="fitness")
            ).order_by("id")
        )
        if len(fitness_sports) > 1:
            primary_fitness = fitness_sports[0]
            primary_fitness.name = "Fitness & Cardio"
            primary_fitness.name_ar = "لياقة بدنية / سويدي"
            primary_fitness.is_pinned = True
            primary_fitness.is_active = True
            primary_fitness.save()

            for dup in fitness_sports[1:]:
                Group.objects.filter(sport=dup).update(sport=primary_fitness)
                dup.delete()
        elif len(fitness_sports) == 1:
            f = fitness_sports[0]
            f.name = "Fitness & Cardio"
            f.name_ar = "لياقة بدنية / سويدي"
            f.is_pinned = True
            f.is_active = True
            f.save()

class Migration(migrations.Migration):

    dependencies = [
        ("departments", "0008_ensure_sports_active"),
    ]

    operations = [
        migrations.RunPython(clean_duplicates_and_update_colors, reverse_code=migrations.RunPython.noop),
    ]
