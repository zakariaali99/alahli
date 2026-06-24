from django.urls import path

from . import views

urlpatterns = [
    path("stats/", views.dashboard_stats, name="analytics-stats"),
    path("monthly-growth/", views.monthly_growth, name="analytics-monthly-growth"),
    path("department-distribution/", views.department_distribution, name="analytics-department-distribution"),
    path("revenue/", views.revenue_by_month, name="analytics-revenue"),
]
