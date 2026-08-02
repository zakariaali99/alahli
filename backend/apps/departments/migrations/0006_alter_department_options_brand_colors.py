from django.db import migrations


def set_brand_colors(apps, schema_editor):
    Department = apps.get_model("departments", "Department")
    for dept in Department.objects.all():
        name = (dept.name or "").lower()
        name_ar = dept.name_ar or ""
        if "aws" in name or "أوس" in name_ar:
            dept.color = "#136F63"
        elif "ahli" in name or "أهلي" in name_ar:
            if dept.color in ("", "#00ff00"):
                dept.color = "#0F4C81"
            else:
                continue
        else:
            continue
        dept.save(update_fields=["color"])


def reverse_noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ("departments", "0005_group_shifts"),
    ]

    operations = [
        migrations.AlterModelOptions(
            name="department",
            options={"ordering": ["id"]},
        ),
        migrations.RunPython(set_brand_colors, reverse_noop),
    ]
