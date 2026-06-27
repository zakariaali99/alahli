from rest_framework import serializers

from .models import Achievement, DailyStat, WeeklyProgress


class DailyStatSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyStat
        fields = ["day_abbr", "day_full", "value", "hours"]


class WeeklyProgressSerializer(serializers.ModelSerializer):
    daily_stats = DailyStatSerializer(many=True, read_only=True)

    class Meta:
        model = WeeklyProgress
        fields = [
            "id", "week_start", "sessions_count", "active_minutes",
            "goal_progress", "goal_target", "daily_stats",
        ]


class AchievementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Achievement
        fields = [
            "id", "icon", "title", "subtitle",
            "status", "unlocked_at",
        ]
