from datetime import date, timedelta

from django.utils.timezone import now
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Achievement, WeeklyProgress
from .serializers import AchievementSerializer, WeeklyProgressSerializer


class WeeklyProgressViewSet(viewsets.ModelViewSet):
    queryset = WeeklyProgress.objects.all()
    serializer_class = WeeklyProgressSerializer

    def get_queryset(self):
        return WeeklyProgress.objects.filter(user=self.request.user)

    @action(detail=False, methods=["get"])
    def weekly(self, request):
        today = now().date()
        week_start = today - timedelta(days=today.weekday())
        week_param = request.query_params.get("week")
        if week_param:
            try:
                week_start = date.fromisoformat(week_param)
            except ValueError:
                pass
        qs = WeeklyProgress.objects.filter(
            user=request.user, week_start=week_start
        ).first()
        if not qs:
            return Response({
                "week_start": week_start.isoformat(),
                "sessions_count": 0,
                "active_minutes": 0,
                "goal_progress": 0.0,
                "goal_target": 5,
                "daily_stats": [],
                "performance": {
                    "title": "لا توجد بيانات",
                    "subtitle": "ابدأ التمرين لتسجيل تقدمك",
                    "rating": "none",
                },
            })
        serializer = WeeklyProgressSerializer(qs)
        data = serializer.data
        data["performance"] = {
            "title": "أداء ممتاز" if qs.sessions_count >= qs.goal_target else "تقدم جيد",
            "subtitle": f"{qs.sessions_count} جلسات هذا الأسبوع",
            "rating": "excellent" if qs.sessions_count >= qs.goal_target else "good",
        }
        return Response(data)

    @action(detail=False, methods=["get"])
    def goals(self, request):
        today = now().date()
        week_start = today - timedelta(days=today.weekday())
        qs = WeeklyProgress.objects.filter(
            user=request.user, week_start=week_start
        ).first()
        if not qs:
            return Response({
                "title": "هدف الأسبوع",
                "progress": 0.0,
                "target_sessions": 5,
                "completed_sessions": 0,
            })
        return Response({
            "title": "هدف الأسبوع",
            "progress": qs.goal_progress,
            "progress_percent": round(qs.goal_progress * 100),
            "target_sessions": qs.goal_target,
            "completed_sessions": qs.sessions_count,
        })

    @action(detail=False, methods=["get"])
    def stats(self, request):
        today = now().date()
        week_start = today - timedelta(days=today.weekday())
        qs = WeeklyProgress.objects.filter(
            user=request.user, week_start=week_start
        ).first()
        if not qs:
            return Response({"metrics": {
                "sessions_count": 0,
                "active_minutes": 0,
            }})
        return Response({"metrics": {
            "sessions_count": qs.sessions_count,
            "active_minutes": qs.active_minutes,
        }})


class AchievementViewSet(viewsets.ModelViewSet):
    serializer_class = AchievementSerializer

    def get_queryset(self):
        return Achievement.objects.filter(user=self.request.user)
