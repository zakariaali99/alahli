class PackageModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final List<String> features;
  final String iconName;
  final String colorClass;
  final int order;

  const PackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.features,
    required this.iconName,
    required this.colorClass,
    required this.order,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) => PackageModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        durationDays: json['duration_days'] as int? ?? 0,
        features: (json['features'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        iconName: json['icon_name'] as String? ?? '',
        colorClass: json['color_class'] as String? ?? '',
        order: json['order'] as int? ?? 0,
      );
}
