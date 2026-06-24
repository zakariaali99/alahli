from rest_framework import serializers

from .models import CartItem, Product, ProductCategory, WishlistItem


class ProductCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductCategory
        fields = ["id", "slug", "display_ar"]


class ProductSerializer(serializers.ModelSerializer):
    category_display = serializers.CharField(source="category.display_ar", read_only=True)
    price_display = serializers.SerializerMethodField()
    original_price_display = serializers.SerializerMethodField()
    sale_percentage = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            "id", "name", "description", "category", "category_display",
            "price", "price_display", "currency", "original_price",
            "original_price_display", "sale_percentage",
            "image_url", "is_new", "in_stock",
        ]

    def get_price_display(self, obj):
        return f"{obj.price} د.ل"

    def get_original_price_display(self, obj):
        if obj.original_price:
            return f"{obj.original_price} د.ل"
        return None

    def get_sale_percentage(self, obj):
        if obj.original_price and obj.original_price > obj.price:
            pct = int((1 - obj.price / obj.original_price) * 100)
            return f"-{pct}%"
        return None


class CartItemSerializer(serializers.ModelSerializer):
    product_detail = ProductSerializer(source="product", read_only=True)

    class Meta:
        model = CartItem
        fields = ["id", "product", "product_detail", "quantity", "added_at"]
        read_only_fields = ["user", "added_at"]


class WishlistItemSerializer(serializers.ModelSerializer):
    product_detail = ProductSerializer(source="product", read_only=True)

    class Meta:
        model = WishlistItem
        fields = ["id", "product", "product_detail", "added_at"]
        read_only_fields = ["user", "added_at"]
