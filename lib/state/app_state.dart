import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/database_helper.dart';
import '../data/mock_data.dart';
import '../models/offer.dart';
import '../models/store.dart';
import '../models/user_role.dart';
import '../services/location_service.dart';

// Autor: Roberto
// Estado global de la app (ChangeNotifier + Provider): sesión, filtros de
// búsqueda, ubicación, tiendas, ofertas y favoritos.

// Coordenadas de respaldo si el usuario no da permiso de ubicación
// (Plaza Murillo, centro de La Paz).
const double _fallbackLat = -16.4950;
const double _fallbackLng = -68.1339;

class AppState extends ChangeNotifier {
  AppState({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  final LocationService _locationService;

  // ---- Ubicación ----
  Position? _position;
  LocationStatus _locationStatus = LocationStatus.error;
  bool _loadingLocation = true;

  bool get loadingLocation => _loadingLocation;
  LocationStatus get locationStatus => _locationStatus;
  bool get usingApproximateLocation => _position == null;

  double get _lat => _position?.latitude ?? _fallbackLat;
  double get _lng => _position?.longitude ?? _fallbackLng;

  Future<void> loadLocation() async {
    _loadingLocation = true;
    notifyListeners();

    final result = await _locationService.getCurrentLocation();
    _locationStatus = result.status;
    _position = result.position;
    _loadingLocation = false;
    notifyListeners();
  }

  String distanceLabelFor(Store store) {
    final meters = _locationService.distanceInMeters(
      lat1: _lat,
      lng1: _lng,
      lat2: store.lat,
      lng2: store.lng,
    );
    return _locationService.formatDistance(meters);
  }

  double distanceMetersFor(Store store) {
    return _locationService.distanceInMeters(
      lat1: _lat,
      lng1: _lng,
      lat2: store.lat,
      lng2: store.lng,
    );
  }

  (double, double) get myLatLng => (_lat, _lng);

  // ---- Búsqueda y filtro ----
  String _activeFilter = 'Todas';
  String _searchQuery = '';

  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;

  void setFilter(String categoryId) {
    _activeFilter = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Store> get filteredStores {
    final query = _searchQuery.trim().toLowerCase();
    final list = allStores.where((store) {
      final matchesCategory = _activeFilter == 'Todas' || store.category == _activeFilter;
      final matchesQuery = query.isEmpty ||
          store.name.toLowerCase().contains(query) ||
          store.neighborhood.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    list.sort((a, b) => distanceMetersFor(a).compareTo(distanceMetersFor(b)));
    return list;
  }

  // ---- Fuente de datos local (SQLite) ----
  //
  // Si la base de datos local falla, la app no se cae: sigue funcionando
  // con los datos en memoria y queda prendida `_dataSourceError` para
  // avisar en la interfaz.
  bool _loadingDataSource = true;
  bool _dataSourceError = false;

  bool get loadingDataSource => _loadingDataSource;
  bool get dataSourceError => _dataSourceError;

  Future<void> loadFromDatabase() async {
    try {
      final savedFavorites = await DatabaseHelper.instance.readFavoriteIds();
      _favoriteOfferIds
        ..clear()
        ..addAll(savedFavorites);

      _merchantOffers = await DatabaseHelper.instance.readMerchantOffers();
      await _loadRealStores();

      final savedSession = await DatabaseHelper.instance.readSessionUser();
      if (savedSession != null) {
        _currentUsername = savedSession['username'];
        _currentUserName = savedSession['name'];
        _currentRole = UserRole.values.byName(savedSession['role']!);
        await _ensureStoreExistsForCurrentDueno();
      }

      _dataSourceError = false;
    } catch (e) {
      // Si la base de datos local no está disponible, seguimos con los
      // datos de ejemplo en memoria en vez de romper la app.
      _dataSourceError = true;
    }
    _loadingDataSource = false;
    notifyListeners();
  }

  // ---- Cuentas, login y tipo de usuario ----
  //
  // La cuenta (usuario + contraseña) vive en SQLite (tabla users, ver
  // DatabaseHelper). El rol Administrador no se elige al registrarse: ya
  // existe una cuenta "admin" sembrada por defecto.
  UserRole? _currentRole;
  String? _currentUserName;
  String? _currentUsername;

  UserRole? get currentRole => _currentRole;
  String? get currentUserName => _currentUserName;
  String? get currentUsername => _currentUsername;
  bool get isLoggedIn => _currentRole != null;

  // Cada cuenta Dueño de tienda tiene su propia tienda real, guardada en
  // SQLite (tabla `stores`) con id determinístico `store-<username>`.
  List<Store> _realStores = [];

  // Catálogo de ejemplo (MockData) más las tiendas reales registradas.
  List<Store> get allStores => [...MockData.stores, ..._realStores];

  // Null si no hay sesión o el rol no es Dueño de tienda.
  String? get myStoreId =>
      (_currentRole == UserRole.dueno && _currentUsername != null) ? 'store-$_currentUsername' : null;

  Store? get myStore {
    final id = myStoreId;
    if (id == null) return null;
    for (final s in _realStores) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> _loadRealStores() async {
    final rows = await DatabaseHelper.instance.readAllStores();
    _realStores = rows.map(_storeFromRow).toList();
  }

  Store _storeFromRow(Map<String, Object?> row) {
    final address = row['address'] as String;
    return Store(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      neighborhood: address,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      rating: 5.0,
      isOpen: true,
      hours: 'Horario no especificado todavía',
      phone: 'No especificado',
      address: address,
      swatchColorValue: 0xFF2F8F5B,
      offers: const [],
      photoPath: row['photo_path'] as String?,
    );
  }

  // Si una cuenta Dueño de tienda no tiene todavía su propia tienda
  // guardada, le crea una de respaldo en vez de dejarla sin tienda.
  Future<void> _ensureStoreExistsForCurrentDueno() async {
    final id = myStoreId;
    if (id == null) return;
    if (_realStores.any((s) => s.id == id)) return;
    await DatabaseHelper.instance.insertStore({
      'id': id,
      'owner_username': _currentUsername,
      'name': '${_currentUserName ?? "Mi"} · tienda',
      'category': MockData.categoryIds.firstWhere((c) => c != 'Todas'),
      'address': 'Dirección no especificada',
      'lat': _fallbackLat,
      'lng': _fallbackLng,
      'photo_path': null,
    });
    await _loadRealStores();
  }

  // Devuelve null si todo salió bien (y entra con la cuenta de una vez), o
  // un mensaje de error para mostrar en el formulario.
  Future<String?> register({
    required String name,
    required String username,
    required String password,
    required UserRole role,
    // Los siguientes solo aplican si role es Dueño de tienda.
    String? storeName,
    String? storeCategory,
    String? storeAddress,
    double? storeLat,
    double? storeLng,
    String? storePhotoPath,
  }) async {
    try {
      final error = await DatabaseHelper.instance.registerUser(
        name: name,
        username: username,
        password: password,
        role: role.name,
      );
      if (error != null) return error;

      if (role == UserRole.dueno) {
        await DatabaseHelper.instance.insertStore({
          'id': 'store-$username',
          'owner_username': username,
          'name': (storeName == null || storeName.trim().isEmpty) ? '$name · tienda' : storeName.trim(),
          'category': storeCategory ?? MockData.categoryIds.firstWhere((c) => c != 'Todas'),
          'address':
              (storeAddress == null || storeAddress.trim().isEmpty) ? 'Dirección no especificada' : storeAddress.trim(),
          'lat': storeLat ?? _fallbackLat,
          'lng': storeLng ?? _fallbackLng,
          'photo_path': storePhotoPath,
        });
        await _loadRealStores();
      }

      _currentUsername = username;
      _currentUserName = name;
      _currentRole = role;
      notifyListeners();
      await DatabaseHelper.instance.saveSessionUsername(username);
      if (_dataSourceError) {
        _dataSourceError = false;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return 'No se pudo conectar con la base de datos. Intenta de nuevo.';
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final account = await DatabaseHelper.instance.login(username, password);
      if (account == null) return false;

      _currentUsername = account['username'];
      _currentUserName = account['name'];
      _currentRole = UserRole.values.byName(account['role']!);
      await _ensureStoreExistsForCurrentDueno();
      notifyListeners();
      await DatabaseHelper.instance.saveSessionUsername(account['username']!);
      if (_dataSourceError) {
        _dataSourceError = false;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _dataSourceError = true;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUsername = null;
    _currentUserName = null;
    _currentRole = null;
    notifyListeners();
    try {
      await DatabaseHelper.instance.clearSession();
    } catch (e) {
      _dataSourceError = true;
      notifyListeners();
    }
  }

  // ---- Favoritos ----
  final Set<String> _favoriteOfferIds = {};

  bool isFavorite(String offerId) => _favoriteOfferIds.contains(offerId);

  void toggleFavorite(String offerId) {
    final willBeFavorite = !_favoriteOfferIds.contains(offerId);
    if (willBeFavorite) {
      _favoriteOfferIds.add(offerId);
    } else {
      _favoriteOfferIds.remove(offerId);
    }
    notifyListeners();
    _persistFavorite(offerId, willBeFavorite);
  }

  Future<void> _persistFavorite(String offerId, bool isFavorite) async {
    try {
      if (isFavorite) {
        await DatabaseHelper.instance.insertFavorite(offerId);
      } else {
        await DatabaseHelper.instance.deleteFavorite(offerId);
      }
      if (_dataSourceError) {
        _dataSourceError = false;
        notifyListeners();
      }
    } catch (e) {
      _dataSourceError = true;
      notifyListeners();
    }
  }

  // Para una tienda de ejemplo usa su catálogo fijo; para una tienda real
  // filtra las ofertas guardadas en SQLite por esa tienda y oculta las
  // que están en pausa.
  List<Offer> offersForStore(Store store) {
    final isRealStore = _realStores.any((s) => s.id == store.id);
    if (isRealStore) {
      return _merchantOffers.where((o) => o.storeId == store.id && !o.paused).toList();
    }
    return store.offers;
  }

  List<Offer> get _allVisibleOffers => allStores.expand(offersForStore).toList();

  List<Offer> get favoriteOffers {
    return _allVisibleOffers.where((o) => _favoriteOfferIds.contains(o.id)).toList();
  }

  Offer? findOffer(String offerId) {
    for (final offer in _allVisibleOffers) {
      if (offer.id == offerId) return offer;
    }
    return null;
  }

  // Devuelve una tienda placeholder en vez de lanzar un error si la oferta
  // quedó huérfana (sin tienda asociada).
  Store storeOfOffer(Offer offer) {
    for (final s in allStores) {
      if (s.id == offer.storeId) return s;
    }
    return const Store(
      id: 'desconocida',
      name: 'Tienda',
      category: '',
      neighborhood: '',
      lat: _fallbackLat,
      lng: _fallbackLng,
      rating: 0,
      isOpen: false,
      hours: '',
      phone: '',
      address: '',
      swatchColorValue: 0xFF9CA3AF,
      offers: [],
    );
  }

  // ---- Panel de comerciante ("mi tienda") ----
  List<Offer> _merchantOffers = [];

  // Todas las ofertas de la plataforma (usado por el Admin para moderar).
  List<Offer> get merchantOffers => List.unmodifiable(_merchantOffers);

  // Solo las de la tienda del Dueño de tienda con sesión iniciada.
  List<Offer> get myMerchantOffers {
    final id = myStoreId;
    if (id == null) return const [];
    return _merchantOffers.where((o) => o.storeId == id).toList();
  }

  int get activeMerchantOffersCount =>
      _merchantOffers.where((o) => !o.paused).length;

  int get myActiveMerchantOffersCount =>
      myMerchantOffers.where((o) => !o.paused).length;

  void togglePauseMerchantOffer(String offerId) {
    Offer? updated;
    _merchantOffers = _merchantOffers.map((o) {
      if (o.id != offerId) return o;
      updated = o.copyWith(paused: !o.paused);
      return updated!;
    }).toList();
    notifyListeners();
    if (updated != null) _persistMerchantOfferUpdate(updated!);
  }

  void addMerchantOffer(Offer offer) {
    _merchantOffers = [..._merchantOffers, offer];
    notifyListeners();
    _persistNewMerchantOffer(offer);
  }

  void editMerchantOffer(Offer updated) {
    _merchantOffers = _merchantOffers.map((o) => o.id == updated.id ? updated : o).toList();
    notifyListeners();
    _persistMerchantOfferUpdate(updated);
  }

  void deleteMerchantOffer(String offerId) {
    _merchantOffers = _merchantOffers.where((o) => o.id != offerId).toList();
    // Si estaba en favoritos de alguien, ya no tiene sentido que siga ahí.
    final wasFavorite = _favoriteOfferIds.remove(offerId);
    notifyListeners();
    _persistMerchantOfferDeletion(offerId, alsoRemoveFavorite: wasFavorite);
  }

  Future<void> _persistMerchantOfferUpdate(Offer offer) async {
    try {
      await DatabaseHelper.instance.updateMerchantOffer(offer);
      if (_dataSourceError) {
        _dataSourceError = false;
        notifyListeners();
      }
    } catch (e) {
      _dataSourceError = true;
      notifyListeners();
    }
  }

  Future<void> _persistNewMerchantOffer(Offer offer) async {
    try {
      await DatabaseHelper.instance.insertMerchantOffer(offer);
      if (_dataSourceError) {
        _dataSourceError = false;
        notifyListeners();
      }
    } catch (e) {
      _dataSourceError = true;
      notifyListeners();
    }
  }

  Future<void> _persistMerchantOfferDeletion(String offerId, {required bool alsoRemoveFavorite}) async {
    try {
      await DatabaseHelper.instance.deleteMerchantOffer(offerId);
      if (alsoRemoveFavorite) {
        await DatabaseHelper.instance.deleteFavorite(offerId);
      }
      if (_dataSourceError) {
        _dataSourceError = false;
        notifyListeners();
      }
    } catch (e) {
      _dataSourceError = true;
      notifyListeners();
    }
  }
}
