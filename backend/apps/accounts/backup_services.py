import json
from datetime import datetime
from django.db import transaction
from django.apps import apps
from django.core.serializers.json import DjangoJSONEncoder

def generate_backup_data():
    """Generates complete dictionary dump of system data."""
    Department = apps.get_model("departments", "Department")
    Sport = apps.get_model("departments", "Sport")
    Group = apps.get_model("departments", "Group")
    User = apps.get_model("accounts", "User")
    Athlete = apps.get_model("athletes", "Athlete")
    SubscriptionPackage = apps.get_model("packages", "SubscriptionPackage")
    Subscription = apps.get_model("subscriptions", "Subscription")
    AttendanceLog = apps.get_model("progress", "AttendanceLog")
    FAQ = apps.get_model("faqs", "FAQ")

    data = {
        "version": "1.0",
        "timestamp": datetime.now().isoformat(),
        "departments": list(Department.objects.all().values()),
        "sports": list(Sport.objects.all().values()),
        "groups": list(Group.objects.all().values()),
        "users": list(User.objects.all().values(
            "id", "phone", "first_name", "last_name", "full_name_ar",
            "role", "academy_id", "is_active", "created_at"
        )),
        "athletes": list(Athlete.objects.all().values()),
        "subscription_packages": list(SubscriptionPackage.objects.all().values()),
        "subscriptions": list(Subscription.objects.all().values()),
        "attendance_logs": list(AttendanceLog.objects.all().values()),
        "faqs": list(FAQ.objects.all().values()),
    }
    return data

@transaction.atomic
def restore_backup_data(backup_dict, mode="smart_merge"):
    """
    Restores backup data with 'smart_merge' or 'overwrite'.
    Smart merge preserves current data and inserts missing backup records.
    """
    Department = apps.get_model("departments", "Department")
    Sport = apps.get_model("departments", "Sport")
    Group = apps.get_model("departments", "Group")
    User = apps.get_model("accounts", "User")
    Athlete = apps.get_model("athletes", "Athlete")
    SubscriptionPackage = apps.get_model("packages", "SubscriptionPackage")
    Subscription = apps.get_model("subscriptions", "Subscription")
    AttendanceLog = apps.get_model("progress", "AttendanceLog")
    FAQ = apps.get_model("faqs", "FAQ")

    stats = {"created": 0, "merged": 0}

    if mode == "overwrite":
        # Clear non-core transactional records
        AttendanceLog.objects.all().delete()
        Subscription.objects.all().delete()
        SubscriptionPackage.objects.all().delete()
        Group.objects.all().delete()

    # 1. Restore/Merge Departments
    dept_map = {} # old_id -> new_obj
    for item in backup_dict.get("departments", []):
        old_id = item.get("id")
        dept, created = Department.objects.get_or_create(
            name_ar=item.get("name_ar"),
            defaults={
                "name": item.get("name") or "",
                "color": item.get("color") or "#0F4C81",
                "is_active": item.get("is_active", True),
            }
        )
        dept_map[old_id] = dept
        if created:
            stats["created"] += 1
        else:
            stats["merged"] += 1

    # 2. Restore/Merge Sports
    sport_map = {} # old_id -> new_obj
    for item in backup_dict.get("sports", []):
        old_id = item.get("id")
        dept_id = item.get("department_id")
        dept = dept_map.get(dept_id) or Department.objects.filter(id=dept_id).first()
        if not dept:
            continue
        
        sport, created = Sport.objects.get_or_create(
            department=dept,
            name_ar=item.get("name_ar"),
            defaults={
                "name": item.get("name") or "",
                "is_pinned": item.get("is_pinned", False),
                "supports_parents": item.get("supports_parents", False),
                "is_active": item.get("is_active", True),
            }
        )
        sport_map[old_id] = sport
        if created:
            stats["created"] += 1
        else:
            stats["merged"] += 1

    # 3. Restore/Merge Groups
    group_map = {}
    for item in backup_dict.get("groups", []):
        old_id = item.get("id")
        sp_id = item.get("sport_id")
        sp = sport_map.get(sp_id) or Sport.objects.filter(id=sp_id).first()
        if not sp:
            continue

        grp, created = Group.objects.get_or_create(
            sport=sp,
            name_ar=item.get("name_ar"),
            defaults={
                "name": item.get("name") or "",
                "age_min": item.get("age_min") or 5,
                "age_max": item.get("age_max") or 18,
                "capacity": item.get("capacity") or 30,
                "is_active": item.get("is_active", True),
            }
        )
        group_map[old_id] = grp
        if created:
            stats["created"] += 1

    # 4. Restore/Merge Users
    user_map = {}
    for item in backup_dict.get("users", []):
        old_id = item.get("id")
        phone = item.get("phone")
        if not phone:
            continue
        
        usr = User.objects.filter(phone=phone).first()
        if not usr:
            usr = User.objects.create(
                phone=phone,
                first_name=item.get("first_name") or "",
                last_name=item.get("last_name") or "",
                full_name_ar=item.get("full_name_ar") or "",
                role=item.get("role") or "athlete",
                is_active=item.get("is_active", True),
            )
            usr.set_password("12345678") # fallback reset password
            usr.save()
            stats["created"] += 1
        else:
            stats["merged"] += 1
        user_map[old_id] = usr

    # 5. Restore/Merge Athletes
    athlete_map = {}
    for item in backup_dict.get("athletes", []):
        old_id = item.get("id")
        m_num = item.get("membership_number")
        phone = item.get("phone_number") or ""
        
        ath = None
        if m_num:
            ath = Athlete.objects.filter(membership_number=m_num).first()
        if not ath and phone:
            ath = Athlete.objects.filter(phone_number=phone).first()
            
        if not ath:
            u_account = user_map.get(item.get("user_account_id"))
            p_account = user_map.get(item.get("parent_account_id"))
            dept = dept_map.get(item.get("department_id")) or Department.objects.filter(id=item.get("department_id")).first()
            grp = group_map.get(item.get("group_id")) or Group.objects.filter(id=item.get("group_id")).first()

            ath = Athlete.objects.create(
                user_account=u_account,
                parent_account=p_account,
                department=dept,
                group=grp,
                first_name=item.get("first_name") or "",
                family_name=item.get("family_name") or "",
                full_name_ar=item.get("full_name_ar") or "",
                phone_number=phone,
                membership_number=m_num,
                birth_date=item.get("birth_date"),
                status=item.get("status") or "approved",
            )
            stats["created"] += 1
        else:
            stats["merged"] += 1
        athlete_map[old_id] = ath

    # 6. Restore/Merge Subscription Packages
    package_map = {}
    for item in backup_dict.get("subscription_packages", []):
        old_id = item.get("id")
        dept = dept_map.get(item.get("department_id")) or Department.objects.filter(id=item.get("department_id")).first()
        sp = sport_map.get(item.get("sport_id")) or Sport.objects.filter(id=item.get("sport_id")).first()
        if not dept:
            continue

        pkg, created = SubscriptionPackage.objects.get_or_create(
            department=dept,
            title=item.get("title"),
            defaults={
                "sport": sp,
                "price": item.get("price") or "0.00",
                "duration_months": item.get("duration_months") or 1,
                "is_active": item.get("is_active", True),
            }
        )
        package_map[old_id] = pkg
        if created:
            stats["created"] += 1

    # 7. Restore/Merge Subscriptions
    for item in backup_dict.get("subscriptions", []):
        ath = athlete_map.get(item.get("athlete_id")) or Athlete.objects.filter(id=item.get("athlete_id")).first()
        pkg = package_map.get(item.get("package_id")) or SubscriptionPackage.objects.filter(id=item.get("package_id")).first()
        if not ath or not pkg:
            continue

        sub, created = Subscription.objects.get_or_create(
            athlete=ath,
            package=pkg,
            start_date=item.get("start_date"),
            defaults={
                "end_date": item.get("end_date"),
                "status": item.get("status") or "active",
                "amount_paid": item.get("amount_paid") or "0.00",
            }
        )
        if created:
            stats["created"] += 1
        else:
            stats["merged"] += 1

    return stats
