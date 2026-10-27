import 'package:geolocator/geolocator.dart';

// Autor: Roberto
// Envuelve el paquete geolocator para pedir permiso y leer la ubicación
// real del dispositivo.

/// Resultado de intentar obtener la ubicación del usuario.
enum LocationStatus {
  ok,
  serviceDisabled, // el GPS del teléfono está apagado
  permissionDenied,
  permissionDeniedForever,
  error,
}

class LocationResult {
  final LocationStatus status;
  final Position? position;

  const LocationResult(this.status, this.position);
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    // Todo el método va en un solo try/catch: cualquier paso depende de un
    // plugin nativo que puede fallar (por ejemplo, un emulador sin Google
    // Play Services), y si eso pasa se usa la ubicación de respaldo en vez
    // de que la app se caiga.
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(LocationStatus.serviceDisabled, null);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(LocationStatus.permissionDenied, null);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.permissionDeniedForever, null);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return LocationResult(LocationStatus.ok, position);
    } catch (_) {
      return const LocationResult(LocationStatus.error, null);
    }
  }

  /// Distancia en metros entre dos puntos (fórmula de Haversine, vía geolocator).
  double distanceInMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
