import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../models/store.dart';
import '../theme/app_theme.dart';

// Autor: Roberto
// Mapa con OpenStreetMap: muestra la ubicación del usuario y un pin por
// cada tienda visible en la lista filtrada.
class StoreMap extends StatelessWidget {
  final (double, double) myLatLng;
  final List<Store> stores;
  final void Function(Store store) onTapStore;

  const StoreMap({
    super.key,
    required this.myLatLng,
    required this.stores,
    required this.onTapStore,
  });

  @override
  Widget build(BuildContext context) {
    final center = latlng.LatLng(myLatLng.$1, myLatLng.$2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: 160,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ferrecerca_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                for (final store in stores)
                  Marker(
                    point: latlng.LatLng(store.lat, store.lng),
                    width: 34,
                    height: 34,
                    child: GestureDetector(
                      onTap: () => onTapStore(store),
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.accent,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
