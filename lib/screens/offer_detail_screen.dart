import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

// Autor: Roberto
// Pantalla de detalle de una oferta: foto, precio, descuento y descripción.
class OfferDetailScreen extends StatelessWidget {
  final String offerId;
  const OfferDetailScreen({super.key, required this.offerId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final offer = appState.findOffer(offerId);
    if (offer == null) {
      // Puede pasar si, por ejemplo, el comerciante pausó la oferta justo
      // mientras un comprador la tenía abierta.
      return Scaffold(
        appBar: AppBar(title: const Text('Oferta no disponible')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Esta oferta ya no está disponible.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final store = appState.storeOfOffer(offer);
    final isFavorite = appState.isFavorite(offer.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: MockData.colorFrom(offer.swatchColorValue),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: () => appState.toggleFavorite(offer.id),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (offer.photoPath != null)
                    Image.file(
                      File(offer.photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: MockData.colorFrom(offer.swatchColorValue)),
                    )
                  else
                    Container(color: MockData.colorFrom(offer.swatchColorValue)),
                  Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    offer.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text.rich(
                      TextSpan(
                        text: 'Vendido por ',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: store.name,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        offer.priceLabel,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          offer.oldPriceLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          offer.discountLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(offer.stockText, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  const Divider(height: 32, color: AppColors.border),
                  const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  const SizedBox(height: 6),
                  Text(
                    offer.description,
                    style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Ver en la tienda'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
