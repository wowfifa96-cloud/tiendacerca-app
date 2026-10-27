import 'dart:io';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/store.dart';
import '../theme/app_theme.dart';

// Autor: Roberto
// Widgets reutilizables (chips, tarjetas, estados vacíos) compartidos por
// varias pantallas.

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.accent,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final bool isOpen;
  const StatusBadge({super.key, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.successBackground : AppColors.closedBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        isOpen ? 'Abierto ahora' : 'Cerrado',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isOpen ? AppColors.success : AppColors.closed,
        ),
      ),
    );
  }
}

// Muestra la foto real de una tienda u oferta, o un color de respaldo si
// no tiene foto. Se llama SwatchBox (no ColorSwatch) para no chocar con la
// clase ColorSwatch de package:flutter/material.dart.
class SwatchBox extends StatelessWidget {
  final int colorValue;
  final double size;
  final double radius;
  final Widget? child;
  final String? imagePath;

  const SwatchBox({
    super.key,
    required this.colorValue,
    this.size = 52,
    this.radius = 12,
    this.child,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Si el archivo de la foto ya no existe, mostramos el color de
          // respaldo en vez de un ícono roto.
          errorBuilder: (context, error, stackTrace) => _colorBox(),
        ),
      );
    }
    return _colorBox();
  }

  Widget _colorBox() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MockData.colorFrom(colorValue),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class StoreCard extends StatelessWidget {
  final Store store;
  final String distanceLabel;
  final int offersCount;
  final VoidCallback onTap;

  const StoreCard({
    super.key,
    required this.store,
    required this.distanceLabel,
    required this.offersCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwatchBox(
                colorValue: store.swatchColorValue,
                imagePath: store.photoPath,
                child: Text(
                  store.initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
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
                          child: Text(
                            store.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                          ),
                        ),
                        Text(
                          distanceLabel,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${store.category} · ${store.neighborhood}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF5A623)),
                        const SizedBox(width: 2),
                        Text(
                          store.ratingLabel,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                        StatusBadge(isOpen: store.isOpen),
                      ],
                    ),
                    if (offersCount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$offersCount ofertas activas',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (trailing != null)
          Text(trailing!, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 30, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
