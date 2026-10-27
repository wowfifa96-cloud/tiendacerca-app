import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/offer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// Autor: Roberto
// Pantalla del rol Administrador: catálogo completo de tiendas y
// moderación (pausar/eliminar) de cualquier oferta publicada.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final stores = appState.allStores;
    final totalStores = stores.length;
    final totalOffersOnPlatform =
        stores.fold<int>(0, (sum, store) => sum + appState.offersForStore(store).length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: AppColors.headerBackground,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Panel de administrador', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 3),
              Text('TiendaCerca · vista general',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  _StatTile(value: '$totalStores', label: 'tiendas en la plataforma'),
                  const SizedBox(width: 8),
                  _StatTile(value: '$totalOffersOnPlatform', label: 'ofertas activas'),
                  const SizedBox(width: 8),
                  _StatTile(value: '${appState.merchantOffers.length}', label: 'publicadas por comerciantes'),
                ],
              ),
              const SizedBox(height: 22),
              Text('Todas las tiendas', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'Catálogo de ejemplo más las tiendas reales que fueron '
                'registrando los Dueños de tienda (con su ubicación y foto).',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              for (final store in stores)
                Card(
                  margin: const EdgeInsets.only(top: 10),
                  child: ListTile(
                    leading: SwatchBox(
                      colorValue: store.swatchColorValue,
                      imagePath: store.photoPath,
                      size: 42,
                      radius: 10,
                    ),
                    title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: Text('${store.category} · ${store.neighborhood}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      '${appState.offersForStore(store).length} ofertas',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Text('Moderar ofertas publicadas', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'Estas sí son datos reales guardados en la base de datos local — el '
                'admin puede pausarlas o eliminarlas aunque no sea su tienda.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (appState.merchantOffers.isEmpty)
                const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Todavía no hay ofertas publicadas',
                  subtitle: 'Cuando un dueño de tienda publique algo, aparecerá acá para moderar.',
                )
              else
                for (final offer in appState.merchantOffers) _AdminOfferRow(offer: offer),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _AdminOfferRow extends StatelessWidget {
  final Offer offer;
  const _AdminOfferRow({required this.offer});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Opacity(
      opacity: offer.paused ? 0.55 : 1,
      child: Card(
        margin: const EdgeInsets.only(top: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SwatchBox(colorValue: offer.swatchColorValue, imagePath: offer.photoPath, size: 48, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(offer.priceLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accent)),
                    const SizedBox(height: 2),
                    Text(
                      offer.paused ? 'Pausada' : 'Publicada',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => appState.togglePauseMerchantOffer(offer.id),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: Text(offer.paused ? 'Reactivar' : 'Pausar', style: const TextStyle(fontSize: 11.5)),
                  ),
                  TextButton(
                    onPressed: () => _confirmAdminDelete(context, appState, offer),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.favorite,
                    ),
                    child: const Text('Eliminar', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmAdminDelete(BuildContext context, AppState appState, Offer offer) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('¿Eliminar esta oferta?'),
      content: Text('Acción de moderación: se eliminará "${offer.name}" de la plataforma.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    appState.deleteMerchantOffer(offer.id);
  }
}
