import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/offer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'publish_offer_screen.dart';
import 'store_detail_screen.dart';

// Autor: Roberto
// Panel "Mi tienda" del rol Dueño de tienda: estadísticas, datos de la
// tienda propia y gestión (publicar/editar/pausar/eliminar) de sus ofertas.
class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  String? _toast;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final myStore = appState.myStore;

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
              const Text('Panel de tu tienda', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 3),
              Text(myStore?.name ?? 'Mi tienda',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              if (myStore == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Preparando tu tienda...',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                )
              else
                Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => StoreDetailScreen(storeId: myStore.id)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          SwatchBox(
                            colorValue: myStore.swatchColorValue,
                            imagePath: myStore.photoPath,
                            size: 48,
                            radius: 10,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${myStore.category} · ${myStore.address}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Toca para ver tu tienda como la ve un comprador',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              if (appState.dataSourceError)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.closedBackground,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.closed),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No se pudo conectar con la base de datos local — tus cambios se ven ahora, pero podrían no guardarse.',
                          style: TextStyle(color: AppColors.closed, fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_toast != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.successBackground,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_toast!,
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      InkWell(
                        onTap: () => setState(() => _toast = null),
                        child: const Icon(Icons.close, size: 16, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  _StatTile(value: '${appState.myActiveMerchantOffersCount}', label: 'ofertas activas'),
                  const SizedBox(width: 8),
                  const _StatTile(value: '214', label: 'visitas este mes'),
                  const SizedBox(width: 8),
                  const _StatTile(value: '37', label: 'favoritos'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Publicar oferta'),
                  onPressed: () async {
                    final published = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const PublishOfferScreen()),
                    );
                    if (published == true) {
                      setState(() => _toast = 'Oferta publicada correctamente');
                    }
                  },
                ),
              ),
              const SizedBox(height: 22),
              Text('Mis ofertas', style: Theme.of(context).textTheme.titleMedium),
              for (final offer in appState.myMerchantOffers)
                _MerchantOfferRow(offer: offer),
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

class _MerchantOfferRow extends StatelessWidget {
  final Offer offer;
  const _MerchantOfferRow({required this.offer});

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
              SwatchBox(
                colorValue: offer.swatchColorValue,
                imagePath: offer.photoPath,
                size: 48,
                radius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(offer.priceLabel,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.accent)),
                        const SizedBox(width: 7),
                        Text(offer.oldPriceLabel,
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textTertiary, decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.paused ? 'Pausada' : 'Publicada · visible para compradores',
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
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => PublishOfferScreen(existingOffer: offer)),
                        );
                      } else if (value == 'delete') {
                        _confirmDeleteOffer(context, appState, offer);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
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

Future<void> _confirmDeleteOffer(BuildContext context, AppState appState, Offer offer) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('¿Eliminar esta oferta?'),
      content: Text('Se eliminará "${offer.name}" de tu tienda. Esta acción no se puede deshacer.'),
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
