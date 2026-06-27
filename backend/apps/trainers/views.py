from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import SAFE_METHODS, IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsReceptionOrAbove

from .models import Trainer, TrainerReview
from .serializers import TrainerClassSerializer, TrainerReviewSerializer, TrainerSerializer


class TrainerViewSet(viewsets.ModelViewSet):
    queryset = Trainer.objects.all().prefetch_related('classes')
    serializer_class = TrainerSerializer
    search_fields = ["full_name_ar", "role"]

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsReceptionOrAbove()]
        return super().get_permissions()

    @action(detail=True, methods=["get"])
    def classes(self, request, pk=None):
        trainer = self.get_object()
        serializer = TrainerClassSerializer(trainer.classes.all(), many=True)
        return Response(serializer.data)


class TrainerReviewViewSet(viewsets.ModelViewSet):
    queryset = TrainerReview.objects.all().select_related('athlete', 'trainer')
    serializer_class = TrainerReviewSerializer
    filterset_fields = ["trainer"]

    def get_permissions(self):
        if self.request.method not in SAFE_METHODS:
            return [IsReceptionOrAbove()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        athlete = getattr(self.request.user, "athlete", None)
        if athlete is None:
            raise PermissionDenied("Only athletes can create reviews.")
        serializer.save(athlete=athlete)
