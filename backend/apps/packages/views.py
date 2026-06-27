from rest_framework import viewsets

from .models import SubscriptionPackage
from .serializers import SubscriptionPackageSerializer


class SubscriptionPackageViewSet(viewsets.ModelViewSet):
    queryset = SubscriptionPackage.objects.all()
    serializer_class = SubscriptionPackageSerializer
    search_fields = ["name"]
