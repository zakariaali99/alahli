from django.db import migrations, models

def pin_and_enable_parents(apps, schema_editor):
    Sport = apps.get_model("departments", "Sport")
    # Pin Karate and Cardio/Fitness, enable parents for Karate
    for sport in Sport.objects.all():
        name_norm = (sport.name_ar or "").replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").lower()
        if "كاراتيه" in name_norm or "karate" in (sport.name or "").lower():
            sport.is_pinned = True
            sport.supports_parents = True
            sport.save()
        elif "سويدي" in name_norm or "لياقة" in name_norm or "cardio" in (sport.name or "").lower() or "fitness" in (sport.name or "").lower():
            sport.is_pinned = True
            sport.save()

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
