from datetime import date, timedelta

from django.db.models import Count
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.athletes.models import Athlete
from apps.subscriptions.models import Subscription


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def dashboard_stats(request):
    today = date.today()
    week_later = today + timedelta(days=7)
    first_of_month = today.replace(day=1)

    total_athletes = Athlete.objects.filter(is_active=True).count()
    active_memberships = Subscription.objects.filter(status=Subscription.Status.ACTIVE).count()
    expired_memberships = Subscription.objects.filter(status=Subscription.Status.EXPIRED).count()
    expiring_soon = Subscription.objects.filter(
        status=Subscription.Status.ACTIVE,
        end_date__gte=today,
        end_date__lte=week_later,
    ).count()
    new_this_month = Athlete.objects.filter(
        is_active=True, created_at__gte=first_of_month
    ).count()

    return Response({
        "total_athletes": total_athletes,
        "active_memberships": active_memberships,
        "expired_memberships": expired_memberships,
        "expiring_soon": expiring_soon,
        "new_this_month": new_this_month,
    })


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def monthly_growth(request):
    from django.db.models.functions import TruncMonth

    data = (
        Athlete.objects.filter(is_active=True)
        .annotate(month=TruncMonth("created_at"))
        .values("month")
        .annotate(count=Count("id"))
        .order_by("month")[:12]
    )

    return Response(list(data))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def department_distribution(request):
    data = (
        Athlete.objects.filter(is_active=True)
        .values("department__name_ar")
        .annotate(count=Count("id"))
    )
    return Response(list(data))
