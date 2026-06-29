from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0006_add_user_photo"),
        ("notifications", "0005_device"),
    ]

    operations = [
        migrations.RemoveField(
            model_name="device",
            name="athlete",
        ),
        migrations.AddField(
            model_name="device",
            name="user",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="devices",
                to="accounts.user",
            ),
        ),
    ]
