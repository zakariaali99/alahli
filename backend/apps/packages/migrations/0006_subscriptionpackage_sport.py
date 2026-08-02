from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):

    dependencies = [
        ("departments", "0007_add_sport_pinned_and_parent"),
        ("packages", "0005_alter_subscriptionpackage_duration_type_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="subscriptionpackage",
            name="sport",
            field=models.ForeignKey(
                blank=True,
                help_text="Sport this package belongs to. Null = available to all sports in department.",
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="packages",
                to="departments.sport",
            ),
        ),
    ]
