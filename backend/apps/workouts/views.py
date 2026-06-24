from datetime import datetime

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Booking, Exercise, SessionCategory, WorkoutSession
from .serializers import (
    BookingSerializer,
    ExerciseSerializer,
    SessionCategorySerializer,
    WorkoutSessionSerializer,
)


class WorkoutSessionViewSet(viewsets.ModelViewSet):
    queryset = WorkoutSession.objects.all()
    serializer_class = WorkoutSessionSerializer
    filterset_fields = ["category", "date"]
    search_fields = ["name", "location"]

    @action(detail=False, methods=["get"])
    def categories(self, request):
        qs = SessionCategory.objects.all()
        serializer = SessionCategorySerializer(qs, many=True)
        return Response(serializer.data)


class ExerciseViewSet(viewsets.ModelViewSet):
    queryset = Exercise.objects.all()
    serializer_class = ExerciseSerializer
    search_fields = ["title", "description"]

    @action(detail=True, methods=["post"])
    def start(self, request, pk=None):
        exercise = self.get_object()
        return Response({
            "exercise_id": exercise.id,
            "started_at": datetime.now(),
            "message": "تم بدء التمرين بنجاح",
        })


class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.all()
    serializer_class = BookingSerializer
    filterset_fields = ["status"]

    def get_queryset(self):
        return Booking.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
