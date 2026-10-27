import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'offer_detail_screen.dart';

// Autor: Roberto
// Pestaña de Favoritos: lista de ofertas guardadas por el usuario.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final offers = appState.favoriteOffers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Favoritos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              const Text('Ofertas que guardaste para después',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Expanded(
          child: offers.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'Aún no tienes ofertas guardadas',
                  subtitle: 'Toca el corazón en cualquier oferta para guardarla aquí.',
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final offer in offers)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => OfferDetailScreen(offerId: offer.id)),
                          ),
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
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(
                                        appState.storeOfOffer(offer).name,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Text(offer.priceLabel,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.accent)),
                                          const SizedBox(width: 6),
                                          Text(offer.oldPriceLabel,
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.textTertiary,
                                                  decoration: TextDecoration.lineThrough)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.favorite, size: 20, color: AppColors.favorite),
                                  onPressed: () => appState.toggleFavorite(offer.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
