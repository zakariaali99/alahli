from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import UserPreference
from .serializers import UserPreferenceSerializer


class UserPreferenceViewSet(viewsets.ModelViewSet):
    queryset = UserPreference.objects.none()
    permission_classes = [IsAuthenticated]
    serializer_class = UserPreferenceSerializer
    http_method_names = ["get", "patch", "head", "options"]

    def get_queryset(self):
        return UserPreference.objects.filter(user=self.request.user)

    def get_object(self):
        pref, _ = UserPreference.objects.get_or_create(user=self.request.user)
        return pref

    def list(self, request, *args, **kwargs):
        pref = self.get_object()
        serializer = self.get_serializer(pref)
        return Response(serializer.data)

    def partial_update(self, request, *args, **kwargs):
        pref = self.get_object()
        serializer = self.get_serializer(pref, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
