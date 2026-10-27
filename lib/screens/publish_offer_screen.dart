import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/offer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

// Autor: Roberto
// Formulario para publicar una oferta nueva o editar una existente.
class PublishOfferScreen extends StatefulWidget {
  /// Si se pasa, la pantalla edita esta oferta en vez de crear una nueva
  /// (precarga los campos y "Publicar oferta" se vuelve "Guardar cambios").
  final Offer? existingOffer;

  const PublishOfferScreen({super.key, this.existingOffer});

  @override
  State<PublishOfferScreen> createState() => _PublishOfferScreenState();
}

class _PublishOfferScreenState extends State<PublishOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existingOffer?.name);
  late final _normalPriceController = TextEditingController(
    text: widget.existingOffer == null ? '' : widget.existingOffer!.oldPrice.toStringAsFixed(0),
  );
  late final _offerPriceController = TextEditingController(
    text: widget.existingOffer == null ? '' : widget.existingOffer!.price.toStringAsFixed(0),
  );
  late final _descriptionController = TextEditingController(text: widget.existingOffer?.description);
  late String _category = widget.existingOffer?.category ?? MockData.categoryIds.firstWhere((c) => c != 'Todas');
  final ImagePicker _picker = ImagePicker();
  late String? _photoPath = widget.existingOffer?.photoPath;

  bool get _isEditing => widget.existingOffer != null;

  @override
  void dispose() {
    _nameController.dispose();
    _normalPriceController.dispose();
    _offerPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publishCategories = MockData.categoryIds.where((c) => c != 'Todas').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar oferta' : 'Nueva oferta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            InkWell(
              onTap: _showPhotoSourceSheet,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: _photoPath == null
                  ? Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_camera_outlined, color: AppColors.textSecondary),
                          const SizedBox(height: 6),
                          const Text(
                            'Toca para agregar una foto',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Image.file(
                            File(_photoPath!),
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Foto agregada · toca para cambiarla',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Nombre del producto'),
            TextFormField(
              key: const Key('publish_offer_name'),
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Ej. Taladro percutor 650W'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Escribe un nombre para la oferta' : null,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Categoría'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: [
                for (final c in publishCategories) DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (value) => setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Precio normal (Bs)'),
                      TextFormField(
                        controller: _normalPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '320'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Precio oferta (Bs)'),
                      TextFormField(
                        key: const Key('publish_offer_price'),
                        controller: _offerPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '249'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Requerido';
                          if (double.tryParse(value) == null) return 'Solo números';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Descripción'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Cuenta a los compradores qué incluye, estado, garantía...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isEditing ? 'Guardar cambios' : 'Publicar oferta'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_photoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Quitar foto'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    setState(() => _photoPath = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1280, imageQuality: 85);
      if (picked != null && mounted) {
        setState(() => _photoPath = picked.path);
      }
    } catch (e) {
      // Permiso denegado o sin cámara disponible: se avisa sin cerrar la pantalla.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la cámara o la galería.')),
        );
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final offerPrice = double.tryParse(_offerPriceController.text) ?? 0;
    final normalPrice = double.tryParse(_normalPriceController.text) ?? offerPrice;
    final appState = context.read<AppState>();
    final description =
        _descriptionController.text.trim().isEmpty ? 'Sin descripción adicional.' : _descriptionController.text.trim();

    final existing = widget.existingOffer;
    if (existing != null) {
      // Se construye el Offer directo (no con copyWith) para que _photoPath
      // en null sí pueda borrar una foto existente.
      final updatedOffer = Offer(
        id: existing.id,
        storeId: existing.storeId,
        name: _nameController.text.trim(),
        category: _category,
        price: offerPrice,
        oldPrice: normalPrice,
        stockText: existing.stockText,
        description: description,
        swatchColorValue: existing.swatchColorValue,
        paused: existing.paused,
        photoPath: _photoPath,
      );
      appState.editMerchantOffer(updatedOffer);
    } else {
      final swatches = [0xFFD9660B, 0xFF2563EB, 0xFF2F8F5B, 0xFF8B5E34, 0xFF0E7490];
      final newOffer = Offer(
        id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
        storeId: appState.myStoreId ?? MockData.myStore.id,
        name: _nameController.text.trim(),
        category: _category,
        price: offerPrice,
        oldPrice: normalPrice,
        stockText: 'Disponible',
        description: description,
        swatchColorValue: swatches[appState.merchantOffers.length % swatches.length],
        photoPath: _photoPath,
      );
      appState.addMerchantOffer(newOffer);
    }

    Navigator.of(context).pop(true);
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
    );
  }
}
