import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/store.dart';
import '../services/location_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/store_map.dart';
import 'store_detail_screen.dart';

// Autor: Roberto
// Pestaña Buscar: mapa y lista de tiendas cercanas, filtrable por categoría.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final stores = appState.filteredStores;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.headerBackground,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TiendaCerca', style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: Colors.white)),
                  const Icon(Icons.store_mall_directory_outlined, color: AppColors.accent),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    _locationSubtitle(appState),
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  TextField(
                    onChanged: appState.setSearchQuery,
                    decoration: const InputDecoration(
                      hintText: 'Busca por nombre o zona...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final categoryId in MockData.categoryIds)
                          CategoryChip(
                            label: categoryId,
                            selected: appState.activeFilter == categoryId,
                            onTap: () => appState.setFilter(categoryId),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  StoreMap(
                    myLatLng: appState.myLatLng,
                    stores: stores,
                    onTapStore: (store) => _openStore(context, store),
                  ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: 'Tiendas cerca de ti',
                    trailing: '${stores.length} ${stores.length == 1 ? "resultado" : "resultados"}',
                  ),
                  if (stores.isEmpty)
                    const EmptyState(
                      icon: Icons.search_off,
                      title: 'No encontramos tiendas con ese filtro',
                      subtitle: 'Prueba con otra categoría o búsqueda.',
                    )
                  else
                    for (final store in stores)
                      StoreCard(
                        store: store,
                        distanceLabel: appState.distanceLabelFor(store),
                        offersCount: appState.offersForStore(store).length,
                        onTap: () => _openStore(context, store),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _locationSubtitle(AppState appState) {
    if (appState.loadingLocation) return 'Ubicando...';
    if (appState.usingApproximateLocation) {
      switch (appState.locationStatus) {
        case LocationStatus.permissionDenied:
        case LocationStatus.permissionDeniedForever:
          return 'La Paz, Bolivia (activa tu ubicación para más precisión)';
        case LocationStatus.serviceDisabled:
          return 'La Paz, Bolivia (activa el GPS del teléfono)';
        default:
          return 'La Paz, Bolivia';
      }
    }
    return 'Cerca de tu ubicación actual';
  }

  void _openStore(BuildContext context, Store store) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StoreDetailScreen(storeId: store.id)),
    );
  }
}
