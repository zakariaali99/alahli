from collections import defaultdict
from datetime import date, timedelta

from django.db.models import Count, Sum, Value
from django.db.models.functions import Coalesce, TruncMonth
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.athletes.models import Athlete
from apps.subscriptions.models import Renewal, Subscription


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

    subscription_revenue = Subscription.objects.aggregate(total=Sum("amount"))["total"] or 0
    renewal_revenue = Renewal.objects.aggregate(total=Sum("amount"))["total"] or 0
    total_revenue = subscription_revenue + renewal_revenue

    total_subscriptions = Subscription.objects.count()
    renewal_count = Renewal.objects.values('subscription').distinct().count()
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
        .values(department_name=Coalesce("department__name_ar", Value("بدون قسم")))
        .annotate(count=Count("id"))
    )
    return Response(list(data))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def revenue_by_month(request):
    subscription_data = (
        Subscription.objects
        .annotate(month=TruncMonth("start_date"))
        .values("month")
        .annotate(revenue=Sum("amount"))
        .order_by("month")[:12]
    )

    renewal_data = (
        Renewal.objects
        .annotate(month=TruncMonth("renewal_date"))
        .values("month")
        .annotate(revenue=Sum("amount"))
        .order_by("month")[:12]
    )

    monthly = defaultdict(float)
    for entry in subscription_data:
        if entry["month"]:
            monthly[entry["month"].isoformat()] += float(entry["revenue"])
    for entry in renewal_data:
        if entry["month"]:
            monthly[entry["month"].isoformat()] += float(entry["revenue"])

    result = [{"month": m, "revenue": r} for m, r in sorted(monthly.items())]
    return Response(result)
