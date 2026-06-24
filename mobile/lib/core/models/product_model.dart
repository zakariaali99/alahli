class ProductCategoryModel {
  final int id;
  final String slug;
  final String displayAr;

  const ProductCategoryModel({
    required this.id,
    required this.slug,
    required this.displayAr,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) =>
      ProductCategoryModel(
        id: json['id'] as int,
        slug: json['slug'] as String? ?? '',
        displayAr: json['display_ar'] as String? ?? '',
      );
}

class ProductModel {
  final int id;
  final String name;
  final String description;
  final int? category;
  final String categoryDisplay;
  final double price;
  final String priceDisplay;
  final String currency;
  final double? originalPrice;
  final String? originalPriceDisplay;
  final String? salePercentage;
  final String imageUrl;
  final bool isNew;
  final bool inStock;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    this.category,
    required this.categoryDisplay,
    required this.price,
    required this.priceDisplay,
    required this.currency,
    this.originalPrice,
    this.originalPriceDisplay,
    this.salePercentage,
    required this.imageUrl,
    required this.isNew,
    required this.inStock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as int?,
        categoryDisplay: json['category_display'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        priceDisplay: json['price_display'] as String? ?? '',
        currency: json['currency'] as String? ?? 'LYD',
        originalPrice: (json['original_price'] as num?)?.toDouble(),
        originalPriceDisplay: json['original_price_display'] as String?,
        salePercentage: json['sale_percentage'] as String?,
        imageUrl: json['image_url'] as String? ?? '',
        isNew: json['is_new'] as bool? ?? false,
        inStock: json['in_stock'] as bool? ?? true,
      );
}
