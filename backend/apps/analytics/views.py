from datetime import date, timedelta

from django.db.models import Count, Sum
from django.db.models.functions import TruncMonth
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

    total_revenue = (
        Subscription.objects.filter(status=Subscription.Status.ACTIVE)
        .aggregate(total=Sum("amount"))["total"] or 0
    )

    total_subscriptions = Subscription.objects.count()
    renewal_count = Subscription.objects.filter(status=Subscription.Status.ACTIVE).count()
    renewal_rate = round((renewal_count / total_subscriptions * 100) if total_subscriptions else 0)

    return Response({
        "total_athletes": total_athletes,
        "active_memberships": active_memberships,
        "expired_memberships": expired_memberships,
        "expiring_soon": expiring_soon,
        "new_this_month": new_this_month,
        "total_revenue": float(total_revenue),
        "renewal_rate": renewal_rate,
    })


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def monthly_growth(request):
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


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def revenue_by_month(request):
    data = (
        Subscription.objects.values("start_date__month", "start_date__year")
        .annotate(
            month=TruncMonth("start_date"),
            revenue=Sum("amount"),
        )
        .values("month", "revenue")
        .order_by("month")[:12]
    )

    result = []
    for entry in data:
        if entry["month"]:
            result.append({
                "month": entry["month"].isoformat(),
                "revenue": float(entry["revenue"]),
            })

    return Response(result)


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
