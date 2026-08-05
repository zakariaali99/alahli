import json
from datetime import datetime, date, time
from decimal import Decimal
from django.db import transaction
from django.apps import apps

def _serialize_value(v):
    if isinstance(v, (datetime, date, time)):
        return v.isoformat()
    if isinstance(v, Decimal):
        return str(v)
    if hasattr(v, "name"):
        return str(v.name) if v.name else None
    return v

def _serialize_list(queryset):
    rows = list(queryset.values())
    for r in rows:
        for k, v in list(r.items()):
            r[k] = _serialize_value(v)
    return rows

def generate_backup_data():
    """Generates complete dictionary dump of system data."""
    Department = apps.get_model("departments", "Department")
    Sport = apps.get_model("departments", "Sport")
    Group = apps.get_model("departments", "Group")
    User = apps.get_model("accounts", "User")
    Athlete = apps.get_model("athletes", "Athlete")
    SubscriptionPackage = apps.get_model("packages", "SubscriptionPackage")
    Subscription = apps.get_model("subscriptions", "Subscription")
    FAQ = apps.get_model("faqs", "FAQ")

    users_data = list(User.objects.all().values(
        "id", "phone", "first_name_ar", "last_name_ar",
        "role", "academy_id", "is_active", "date_joined"
    ))
    for u in users_data:
        for k, v in list(u.items()):
            u[k] = _serialize_value(v)

    data = {
        "version": "1.0",
        "timestamp": datetime.now().isoformat(),
        "departments": _serialize_list(Department.objects.all()),
        "sports": _serialize_list(Sport.objects.all()),
        "groups": _serialize_list(Group.objects.all()),
        "users": users_data,
        "athletes": _serialize_list(Athlete.objects.all()),
        "subscription_packages": _serialize_list(SubscriptionPackage.objects.all()),
        "subscriptions": _serialize_list(Subscription.objects.all()),
        "faqs": _serialize_list(FAQ.objects.all()),
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

    stats = {"created": 0, "merged": 0}

    if mode == "overwrite":
        Subscription.objects.all().delete()
        SubscriptionPackage.objects.all().delete()
        Group.objects.all().delete()

    # 1. Restore/Merge Departments
    dept_map = {}
    for item in backup_dict.get("departments", []):
        old_id = item.get("id")
        name_ar = item.get("name_ar") or item.get("name") or f"قسم {old_id}"
        dept, created = Department.objects.get_or_create(
            name_ar=name_ar,
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
    sport_map = {}
    for item in backup_dict.get("sports", []):
        old_id = item.get("id")
        dept_id = item.get("department_id")
        dept = dept_map.get(dept_id) or Department.objects.filter(id=dept_id).first()
        if not dept:
            continue
        
        name_ar = item.get("name_ar") or item.get("name") or f"رياضة {old_id}"
        sport, created = Sport.objects.get_or_create(
            department=dept,
            name_ar=name_ar,
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

        name_ar = item.get("name_ar") or item.get("name") or f"مجموعة {old_id}"
        grp, created = Group.objects.get_or_create(
            sport=sp,
            name_ar=name_ar,
            defaults={
                "days": item.get("days") or item.get("schedule_days") or "",
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
                first_name_ar=item.get("first_name_ar") or "",
                last_name_ar=item.get("last_name_ar") or "",
                role=item.get("role") or "athlete",
                is_active=item.get("is_active", True),
            )
            stats["created"] += 1
        else:
            stats["merged"] += 1
        user_map[old_id] = usr

    # 5. Restore/Merge Athletes
    athlete_map = {}
    for item in backup_dict.get("athletes", []):
        old_id = item.get("id")
        m_num = item.get("membership_number")
        phone = item.get("phone") or item.get("phone_number") or f"child_{old_id}"
        full_name = item.get("full_name") or item.get("full_name_ar") or f"{item.get('first_name', '')} {item.get('family_name', '')}".strip() or "رياضي"
        
        ath = None
        if m_num:
            ath = Athlete.objects.filter(membership_number=m_num).first()
        if not ath and phone:
            ath = Athlete.objects.filter(phone=phone).first()
            
        if not ath:
            dept = dept_map.get(item.get("department_id")) or Department.objects.filter(id=item.get("department_id")).first()
            sp = sport_map.get(item.get("sport_id")) or Sport.objects.filter(id=item.get("sport_id")).first()
            b_date = item.get("birth_date") or "2010-01-01"

            ath = Athlete.objects.create(
                full_name=full_name,
                phone=phone,
                parent_name=item.get("parent_name") or "",
                parent_phone=item.get("parent_phone") or "",
                membership_number=m_num or f"ALA-{old_id}",
                birth_date=b_date,
                gender=item.get("gender") or "male",
                department=dept,
                sport=sp,
                health_status=item.get("health_status") or "",
                notes=item.get("notes") or "",
                is_active=item.get("is_active", True),
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

        pkg_name = item.get("name") or item.get("title") or f"باقة {old_id}"
        pkg, created = SubscriptionPackage.objects.get_or_create(
            department=dept,
            name=pkg_name,
            defaults={
                "sport": sp,
                "price": item.get("price") or "0.00",
                "renewal_price": item.get("renewal_price") or item.get("price") or "0.00",
                "duration_type": item.get("duration_type") or "months",
                "duration_value": item.get("duration_value") or item.get("duration_months") or 1,
                "is_active": item.get("is_active", True),
            }
        )
        package_map[old_id] = pkg
        if created:
            stats["created"] += 1

    # 7. Restore/Merge Subscriptions
    for item in backup_dict.get("subscriptions", []):
        old_sub_id = item.get("id")
        ath = athlete_map.get(item.get("athlete_id")) or Athlete.objects.filter(id=item.get("athlete_id")).first()
        grp = group_map.get(item.get("group_id")) or Group.objects.filter(id=item.get("group_id")).first()
        if not ath:
            continue

        start_d = item.get("start_date") or "2026-01-01"
        end_d = item.get("end_date") or "2026-02-01"
        amt = item.get("amount") or item.get("amount_paid") or "0.00"

        sub, created = Subscription.objects.get_or_create(
            athlete=ath,
            start_date=start_d,
            defaults={
                "group": grp,
                "end_date": end_d,
                "amount": amt,
                "payment_method": item.get("payment_method") or "cash",
                "status": item.get("status") or "active",
            }
        )
        if created:
            stats["created"] += 1
        else:
            stats["merged"] += 1

    return stats
