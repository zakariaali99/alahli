from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Trainer
from .serializers import TrainerClassSerializer, TrainerSerializer


class TrainerViewSet(viewsets.ModelViewSet):
    queryset = Trainer.objects.all()
    serializer_class = TrainerSerializer
    search_fields = ["full_name_ar", "role"]

    @action(detail=True, methods=["get"])
    def classes(self, request, pk=None):
        trainer = self.get_object()
        serializer = TrainerClassSerializer(trainer.classes.all(), many=True)
        return Response(serializer.data)
