from rest_framework.routers import DefaultRouter

from .views import CartItemViewSet, ProductViewSet, WishlistItemViewSet

router = DefaultRouter()
router.register(r"products", ProductViewSet, basename="product")
router.register(r"cart", CartItemViewSet, basename="cart")
router.register(r"wishlist", WishlistItemViewSet, basename="wishlist")

urlpatterns = router.urls
