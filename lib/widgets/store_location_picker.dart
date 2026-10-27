import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../theme/app_theme.dart';

// Autor: Roberto
// Mini mapa para elegir la ubicación de una tienda: toca un punto del mapa
// para mover el marcador ahí.
class StoreLocationPicker extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final void Function(double lat, double lng) onChanged;

  const StoreLocationPicker({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.onChanged,
  });

  @override
  State<StoreLocationPicker> createState() => _StoreLocationPickerState();
}

class _StoreLocationPickerState extends State<StoreLocationPicker> {
  late latlng.LatLng _picked = latlng.LatLng(widget.initialLat, widget.initialLng);

  @override
  void didUpdateWidget(covariant StoreLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resincroniza el marcador si el padre actualiza la ubicación inicial
    // (por ejemplo, cuando llega el GPS real después de montar el widget).
    if (oldWidget.initialLat != widget.initialLat || oldWidget.initialLng != widget.initialLng) {
      _picked = latlng.LatLng(widget.initialLat, widget.initialLng);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _picked,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
            onTap: (tapPosition, point) {
              setState(() => _picked = point);
              widget.onChanged(point.latitude, point.longitude);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ferrecerca_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _picked,
                  width: 34,
                  height: 34,
                  child: const Icon(Icons.location_on, color: AppColors.accent, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
