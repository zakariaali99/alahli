from collections import defaultdict
from datetime import date, timedelta

from django.db.models import Count, Sum, Value
from django.db.models.functions import Coalesce, TruncMonth
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.athletes.models import Athlete
from apps.subscriptions.models import Renewal, Subscription
from apps.departments.models import Department


def _get_academy(request):
    user = request.user
    academy = getattr(user, "academy", None)
    if academy is None and request.query_params.get("academy_id"):
        try:
            academy = Department.objects.get(id=request.query_params.get("academy_id"))
        except (ValueError, Department.DoesNotExist):
            pass
    return academy


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def dashboard_stats(request):
    today = date.today()
    week_later = today + timedelta(days=7)
    first_of_month = today.replace(day=1)
    academy = _get_academy(request)

    athletes_qs = Athlete.objects.filter(is_active=True)
    subs_qs = Subscription.objects.all()
    renewals_qs = Renewal.objects.all()

    if academy is not None:
        athletes_qs = athletes_qs.filter(department=academy)
        subs_qs = subs_qs.filter(athlete__department=academy)
        renewals_qs = renewals_qs.filter(subscription__athlete__department=academy)

    total_athletes = athletes_qs.count()
    active_memberships = subs_qs.filter(status=Subscription.Status.ACTIVE).count()
    expired_memberships = subs_qs.filter(status=Subscription.Status.EXPIRED).count()
    expiring_soon = subs_qs.filter(
        status=Subscription.Status.ACTIVE,
        end_date__gte=today,
        end_date__lte=week_later,
    ).count()
    new_this_month = athletes_qs.filter(created_at__gte=first_of_month).count()

    subscription_revenue = subs_qs.filter(status__in=[Subscription.Status.ACTIVE, Subscription.Status.EXPIRED]).aggregate(total=Sum("amount"))["total"] or 0
    renewal_revenue = renewals_qs.aggregate(total=Sum("amount"))["total"] or 0
    total_revenue = subscription_revenue + renewal_revenue

    total_subscriptions = subs_qs.count()
    renewal_count = renewals_qs.values('subscription').distinct().count()
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
    academy = _get_academy(request)
    qs = Athlete.objects.filter(is_active=True)
    if academy is not None:
        qs = qs.filter(department=academy)

    data = (
        qs
        .annotate(month=TruncMonth("created_at"))
        .values("month")
        .annotate(count=Count("id"))
        .order_by("month")[:12]
    )

    return Response(list(data))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def department_distribution(request):
    academy = _get_academy(request)
    qs = Athlete.objects.filter(is_active=True)
    if academy is not None:
        qs = qs.filter(department=academy)

    data = (
        qs
        .values(department_name=Coalesce("department__name_ar", Value("بدون قسم")))
        .annotate(count=Count("id"))
    )
    return Response(list(data))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def revenue_by_month(request):
    academy = _get_academy(request)
    subs_qs = Subscription.objects.all()
    renewals_qs = Renewal.objects.all()

    if academy is not None:
        subs_qs = subs_qs.filter(athlete__department=academy)
        renewals_qs = renewals_qs.filter(subscription__athlete__department=academy)

    subscription_data = (
        subs_qs
        .filter(status__in=[Subscription.Status.ACTIVE, Subscription.Status.EXPIRED])
        .annotate(month=TruncMonth("start_date"))
        .values("month")
        .annotate(revenue=Sum("amount"))
        .order_by("month")[:12]
    )

    renewal_data = (
        renewals_qs
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
