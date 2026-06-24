from django.contrib import admin

from .models import CartItem, Product, ProductCategory, WishlistItem

admin.site.register(ProductCategory)
admin.site.register(Product)
admin.site.register(CartItem)
admin.site.register(WishlistItem)
