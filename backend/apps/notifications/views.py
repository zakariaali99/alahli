from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsReceptionOrAbove

from .models import Announcement, Device, Notification
from .serializers import AnnouncementSerializer, DeviceSerializer, NotificationSerializer


class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    filterset_fields = ["is_read"]

    def get_queryset(self):
        user = self.request.user
        if user.role in ["super_admin", "reception"]:
            qs = Notification.objects.all()
            athlete_id = self.request.query_params.get("athlete")
            if athlete_id:
                return qs.filter(athlete_id=athlete_id)
            return qs
        athlete = getattr(user, "athlete", None)
        if athlete:
            return Notification.objects.filter(athlete=athlete)
        return Notification.objects.none()

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsReceptionOrAbove()]
        return [IsAuthenticated()]

    @action(detail=True, methods=["post"])
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response(NotificationSerializer(notification).data)

    @action(detail=False, methods=["post"])
    def mark_all_read(self, request):
        athlete_id = request.query_params.get("athlete") or getattr(getattr(request.user, "athlete", None), "id", None)
        if not athlete_id:
            return Response({"detail": "athlete_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        self.get_queryset().filter(athlete_id=athlete_id).update(is_read=True)
        return Response({"detail": "All notifications marked as read"})


class AnnouncementViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Announcement.objects.filter(is_active=True)
    serializer_class = AnnouncementSerializer


class DeviceViewSet(mixins.CreateModelMixin, viewsets.GenericViewSet):
    serializer_class = DeviceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Device.objects.filter(user=self.request.user)

    def create(self, request, *args, **kwargs):
        fcm_token = request.data.get("fcm_token")
        platform = request.data.get("platform", "android")

        if not fcm_token:
            return Response({"detail": "fcm_token is required"}, status=status.HTTP_400_BAD_REQUEST)

        device, created = Device.objects.update_or_create(
            fcm_token=fcm_token,
            defaults={"user": request.user, "platform": platform, "is_active": True},
        )
        serializer = self.get_serializer(device)
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
