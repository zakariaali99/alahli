from datetime import date

import factory
from django.contrib.auth.hashers import make_password

from apps.accounts.models import User
from apps.athletes.models import Athlete
from apps.departments.models import Department
from apps.subscriptions.models import Subscription, Renewal


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    phone = factory.Sequence(lambda n: f"091{n:07d}")
    first_name_ar = "مشرف"
    last_name_ar = "النظام"
    password = make_password("testpass123")
    role = User.Role.SUPER_ADMIN
    is_staff = True
    is_active = True

    class Params:
        reception = factory.Trait(role=User.Role.RECEPTION, first_name_ar="استقبال", last_name_ar="النادي", is_staff=False)
        viewer = factory.Trait(role=User.Role.VIEWER, is_staff=False)


class DepartmentFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Department

    name = factory.Sequence(lambda n: f"Department {n}")
    name_ar = factory.Sequence(lambda n: f"القسم {n}")
    color = "#1487D4"
    is_active = True


class AthleteFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Athlete

    full_name = factory.Sequence(lambda n: f"لاعب {n}")
    phone = factory.Sequence(lambda n: f"092{n:07d}")
    parent_phone = ""
    birth_date = date(2000, 1, 15)
    gender = Athlete.Gender.MALE
    department = factory.SubFactory(DepartmentFactory)
    notes = ""
    is_active = True


class SubscriptionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Subscription

    athlete = factory.SubFactory(AthleteFactory)
    start_date = date.today()
    end_date = factory.LazyFunction(lambda: date.today())
    amount = 250.00
    status = Subscription.Status.ACTIVE


class RenewalFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Renewal

    subscription = factory.SubFactory(SubscriptionFactory)
    amount = 250.00
    months = 6
