// Autor: Roberto
// Modelo de datos de una oferta o producto publicado por una tienda.
class Offer {
  final String id;
  final String storeId;
  final String name;
  final String category;
  final double price;
  final double oldPrice;
  final String stockText;
  final String description;
  final int swatchColorValue; // color de respaldo si no hay foto real
  final bool paused;

  // Ruta local de la foto real (null = usa swatchColorValue como respaldo).
  final String? photoPath;

  const Offer({
    required this.id,
    required this.storeId,
    required this.name,
    required this.category,
    required this.price,
    required this.oldPrice,
    required this.stockText,
    required this.description,
    required this.swatchColorValue,
    this.paused = false,
    this.photoPath,
  });

  int get discountPercent {
    if (oldPrice <= 0) return 0;
    return (100 - (price / oldPrice * 100)).round();
  }

  String get priceLabel => 'Bs ${price.toStringAsFixed(0)}';
  String get oldPriceLabel => 'Bs ${oldPrice.toStringAsFixed(0)}';
  String get discountLabel => '-$discountPercent%';

  Offer copyWith({
    String? name,
    String? category,
    double? price,
    double? oldPrice,
    String? stockText,
    String? description,
    int? swatchColorValue,
    bool? paused,
    String? photoPath,
  }) {
    return Offer(
      id: id,
      storeId: storeId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      stockText: stockText ?? this.stockText,
      description: description ?? this.description,
      swatchColorValue: swatchColorValue ?? this.swatchColorValue,
      paused: paused ?? this.paused,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
