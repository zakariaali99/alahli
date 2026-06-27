from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.accounts.permissions import IsReceptionOrAbove, IsSuperAdminOrReadOnly

from .filters import AthleteFilter
from .models import Athlete
from .serializers import AthleteDetailSerializer, AthleteListSerializer


class AthleteViewSet(viewsets.ModelViewSet):
    queryset = Athlete.objects.filter(is_active=True).select_related('department')
    filterset_class = AthleteFilter
    search_fields = ["full_name", "membership_number", "phone"]

    def get_serializer_class(self):
        if self.action == "list":
            return AthleteListSerializer
        return AthleteDetailSerializer

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsReceptionOrAbove()]
        return [IsSuperAdminOrReadOnly()]

    @action(detail=False, methods=["get"], url_path="verify/(?P<membership_number>[^/.]+)")
    def verify(self, request, membership_number=None):
        try:
            athlete = Athlete.objects.select_related('department').prefetch_related('subscriptions').get(membership_number=membership_number, is_active=True)
        except Athlete.DoesNotExist:
            return Response(
                {"active": False, "detail": "Membership not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        subscription = athlete.subscriptions.filter(status="active").first()
        return Response({
            "active": bool(subscription),
            "athlete_id": athlete.id,
            "athlete_name": athlete.full_name,
            "department": athlete.department.name_ar if athlete.department else "",
            "expiry_date": subscription.end_date if subscription else None,
            "membership_number": athlete.membership_number,
            "subscription_id": subscription.id if subscription else None,
        })
