from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import CartItem, Product, ProductCategory, WishlistItem
from .serializers import (
    CartItemSerializer,
    ProductCategorySerializer,
    ProductSerializer,
    WishlistItemSerializer,
)


class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.filter(in_stock=True)
    serializer_class = ProductSerializer
    filterset_fields = ["category"]
    search_fields = ["name", "description"]

    @action(detail=False, methods=["get"])
    def categories(self, request):
        qs = ProductCategory.objects.all()
        serializer = ProductCategorySerializer(qs, many=True)
        return Response(serializer.data)


class CartItemViewSet(viewsets.ModelViewSet):
    serializer_class = CartItemSerializer
    filterset_fields = ["product"]

    def get_queryset(self):
        return CartItem.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class WishlistItemViewSet(viewsets.ModelViewSet):
    serializer_class = WishlistItemSerializer
    filterset_fields = ["product"]

    def get_queryset(self):
        return WishlistItem.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["delete"])
    def remove(self, request, pk=None):
        item = self.get_object()
        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
