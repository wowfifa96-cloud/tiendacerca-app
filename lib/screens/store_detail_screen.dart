import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/mock_data.dart';
import '../models/offer.dart';
import '../models/store.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'offer_detail_screen.dart';

// Autor: Roberto
// Pantalla de detalle de una tienda: foto, ubicación, horario y sus ofertas.
class StoreDetailScreen extends StatefulWidget {
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  bool _showOffers = true;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    Store? store;
    for (final s in appState.allStores) {
      if (s.id == widget.storeId) {
        store = s;
        break;
      }
    }
    if (store == null) {
      // Evita un StateError si storeId no corresponde a ninguna tienda.
      return Scaffold(
        appBar: AppBar(title: const Text('Tienda no disponible')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Esta tienda ya no está disponible.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: MockData.colorFrom(store.swatchColorValue),
              image: store.photoPath == null
                  ? null
                  : DecorationImage(
                      image: FileImage(File(store.photoPath!)),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.35),
                        BlendMode.darken,
                      ),
                      // Si el archivo ya no existe, se ve el color de respaldo.
                      onError: (exception, stackTrace) {},
                    ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 20, 18),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          store.statusLabel,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
                        const SizedBox(height: 3),
                        Text('${store.category} · ${store.neighborhood}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF5A623)),
                            const SizedBox(width: 4),
                            Text(store.ratingLabel,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('  ·  ${appState.distanceLabelFor(store)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openMaps(store!),
                    icon: const Icon(Icons.directions, size: 17),
                    label: const Text('Cómo llegar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _call(store!),
                    icon: const Icon(Icons.call_outlined, size: 17),
                    label: const Text('Llamar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StoreTabButton(
                  label: 'Ofertas',
                  selected: _showOffers,
                  onTap: () => setState(() => _showOffers = true),
                ),
                _StoreTabButton(
                  label: 'Información',
                  selected: !_showOffers,
                  onTap: () => setState(() => _showOffers = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: _showOffers
                  ? _OffersList(store: store)
                  : _InfoSection(store: store),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(Store store) async {
    final uri = Uri.parse('geo:${store.lat},${store.lng}?q=${store.lat},${store.lng}(${Uri.encodeComponent(store.name)})');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Respaldo si el esquema geo: no está disponible en el dispositivo.
      final fallback = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${store.lat},${store.lng}');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(Store store) async {
    final uri = Uri.parse('tel:${store.phone}');
    await launchUrl(uri);
  }
}

class _StoreTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StoreTabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _OffersList extends StatelessWidget {
  final Store store;
  const _OffersList({required this.store});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final offers = appState.offersForStore(store);
    if (offers.isEmpty) {
      return const EmptyState(
        icon: Icons.local_offer_outlined,
        title: 'Esta tienda no tiene ofertas activas por ahora',
        subtitle: 'Vuelve más tarde para ver sus próximas promociones.',
      );
    }
    return ListView(
      children: [
        for (final offer in offers) _OfferRow(offer: offer, isFavorite: appState.isFavorite(offer.id)),
      ],
    );
  }
}

class _OfferRow extends StatelessWidget {
  final Offer offer;
  final bool isFavorite;
  const _OfferRow({required this.offer, required this.isFavorite});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _openOffer(context),
              child: SwatchBox(
                colorValue: offer.swatchColorValue,
                imagePath: offer.photoPath,
                size: 56,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openOffer(context),
                          child: Text(
                            offer.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite ? AppColors.favorite : AppColors.textSecondary,
                        ),
                        onPressed: () => appState.toggleFavorite(offer.id),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(offer.priceLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.accent)),
                      const SizedBox(width: 7),
                      Text(offer.oldPriceLabel,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary, decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 7),
                      Text(offer.discountLabel,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openOffer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OfferDetailScreen(offerId: offer.id)),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Store store;
  const _InfoSection({required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(icon: Icons.place_outlined, title: 'Dirección', value: store.address),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.access_time, title: 'Horario', value: store.hours),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.call_outlined, title: 'Teléfono', value: store.phone),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
