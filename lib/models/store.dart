import 'offer.dart';

// Autor: Roberto
// Modelo de datos de una tienda o comercio local (ferretería, abarrotes,
// ropa, farmacia, electrónica, restaurante, entre otros).
class Store {
  final String id;
  final String name;
  final String category;
  final String neighborhood;
  final double lat;
  final double lng;
  final double rating;
  final bool isOpen;
  final String hours;
  final String phone;
  final String address;
  final int swatchColorValue;
  final List<Offer> offers;

  // Foto real de la tienda (null = usa swatchColorValue como respaldo).
  final String? photoPath;

  const Store({
    required this.id,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.isOpen,
    required this.hours,
    required this.phone,
    required this.address,
    required this.swatchColorValue,
    required this.offers,
    this.photoPath,
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
  String get ratingLabel => rating.toStringAsFixed(1);
  String get statusLabel => isOpen ? 'Abierto ahora' : 'Cerrado';
}
