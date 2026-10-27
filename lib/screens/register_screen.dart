import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/user_role.dart';
import '../services/location_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/store_location_picker.dart';

// Autor: Roberto
// Pantalla de registro: crea una cuenta (Cliente o Dueño de tienda); si es
// Dueño de tienda, también registra su propia tienda (ubicación y foto).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// Punto de respaldo si no se puede leer el GPS: Plaza Murillo, La Paz.
const double _fallbackLat = -16.4950;
const double _fallbackLng = -68.1339;

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  UserRole _role = UserRole.cliente;
  bool _loading = false;
  String? _error;

  final LocationService _locationService = LocationService();
  double _storeLat = _fallbackLat;
  double _storeLng = _fallbackLng;
  bool _locationPickedByHand = false;
  late String _storeCategory = MockData.categoryIds.firstWhere((c) => c != 'Todas');
  final ImagePicker _picker = ImagePicker();
  String? _storePhotoPath;

  static const _selectableRoles = [UserRole.cliente, UserRole.dueno];

  @override
  void initState() {
    super.initState();
    _tryPrefillLocation();
  }

  Future<void> _tryPrefillLocation() async {
    // Mejor esfuerzo: si hay GPS real, se usa para prellenar el mapa.
    final result = await _locationService.getCurrentLocation();
    if (!mounted || _locationPickedByHand) return;
    final position = result.position;
    if (position != null) {
      setState(() {
        _storeLat = position.latitude;
        _storeLng = position.longitude;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final isDueno = _role == UserRole.dueno;
    final error = await context.read<AppState>().register(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          role: _role,
          storeName: isDueno ? _storeNameController.text.trim() : null,
          storeCategory: isDueno ? _storeCategory : null,
          storeAddress: isDueno ? _storeAddressController.text.trim() : null,
          storeLat: isDueno ? _storeLat : null,
          storeLng: isDueno ? _storeLng : null,
          storePhotoPath: isDueno ? _storePhotoPath : null,
        );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }
    // AppState.register ya inicia sesión automáticamente.
    Navigator.of(context).pop();
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
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_storePhotoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Quitar foto'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    setState(() => _storePhotoPath = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1280, imageQuality: 85);
      if (picked != null && mounted) {
        setState(() => _storePhotoPath = picked.path);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea tu cuenta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.closedBackground,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.closed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppColors.closed, fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              TextFormField(
                key: const Key('register_name'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Escribe tu nombre' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('register_username'),
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Escribe un usuario';
                  if (value.trim().contains(' ')) return 'El usuario no puede tener espacios';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('register_password'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Escribe una contraseña';
                  if (value.length < 4) return 'Mínimo 4 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('register_confirm'),
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirma la contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) =>
                    (value != _passwordController.text) ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 20),
              Text('Quiero entrar como', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ..._selectableRoles.map(
                (role) => RadioListTile<UserRole>(
                  key: Key('register_role_${role.name}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(role.label),
                  subtitle: Text(role.description, style: const TextStyle(fontSize: 12)),
                  value: role,
                  groupValue: _role,
                  onChanged: (value) => setState(() => _role = value!),
                ),
              ),
              if (_role == UserRole.dueno) ...[
                const SizedBox(height: 6),
                const Divider(color: AppColors.border),
                const SizedBox(height: 10),
                Text('Tu tienda', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                const Text(
                  'Esta es la información de tu propia tienda: va a aparecer '
                  'así para quienes la busquen en TiendaCerca.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('register_store_name'),
                  controller: _storeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de tu tienda',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (value) {
                    if (_role != UserRole.dueno) return null;
                    return (value == null || value.trim().isEmpty) ? 'Escribe el nombre de tu tienda' : null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: const Key('register_store_category'),
                  initialValue: _storeCategory,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [
                    for (final c in MockData.categoryIds.where((c) => c != 'Todas'))
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (value) => setState(() => _storeCategory = value ?? _storeCategory),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('register_store_address'),
                  controller: _storeAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    hintText: 'Ej. Av. 20 de Octubre #2145, Sopocachi',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Toca el mapa para marcar dónde está tu tienda',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                StoreLocationPicker(
                  initialLat: _storeLat,
                  initialLng: _storeLng,
                  onChanged: (lat, lng) {
                    _locationPickedByHand = true;
                    setState(() {
                      _storeLat = lat;
                      _storeLng = lng;
                    });
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'Ubicación elegida: ${_storeLat.toStringAsFixed(4)}, ${_storeLng.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _showPhotoSourceSheet,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: _storePhotoPath == null
                      ? Container(
                          height: 100,
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
                                'Toca para agregar una foto de tu tienda (opcional)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
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
                                File(_storePhotoPath!),
                                height: 100,
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
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Crear cuenta y entrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
