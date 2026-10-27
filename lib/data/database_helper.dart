import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/offer.dart';

// Autor: Roberto
// Acceso a la base de datos local (SQLite): cuentas, sesión, tiendas,
// ofertas del comerciante y favoritos.

const _defaultAdminUsername = 'admin';
const _defaultAdminPassword = 'admin123';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await _open();
    _db = opened;
    return opened;
  }

  Future<Database> _open() async {
    final dbDirectory = await getDatabasesPath();
    final dbPath = p.join(dbDirectory, 'tiendacerca.db');

    return openDatabase(
      dbPath,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            offer_id TEXT PRIMARY KEY
          )
        ''');
        await db.execute('''
          CREATE TABLE merchant_offers (
            id TEXT PRIMARY KEY,
            store_id TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price REAL NOT NULL,
            old_price REAL NOT NULL,
            stock_text TEXT NOT NULL,
            description TEXT NOT NULL,
            swatch_color_value INTEGER NOT NULL,
            paused INTEGER NOT NULL DEFAULT 0,
            photo_path TEXT
          )
        ''');
        await _createUsersAndSessionTables(db);
        await _createStoresTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE merchant_offers ADD COLUMN photo_path TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_session (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              name TEXT NOT NULL,
              role TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          // La tabla app_session anterior no guardaba un usuario real, así
          // que se reemplaza por una con cuentas (cada sesión abierta con
          // el esquema viejo deberá iniciar sesión una vez más).
          await db.execute('DROP TABLE IF EXISTS app_session');
          await _createUsersAndSessionTables(db);
        }
        if (oldVersion < 5) {
          await _createStoresTable(db);
        }
      },
    );
  }

  Future<void> _createUsersAndSessionTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        username TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE app_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        username TEXT NOT NULL
      )
    ''');
    // Cuenta de Administrador sembrada por defecto, para entrar con el
    // mismo formulario de login que cualquier otra cuenta.
    await db.insert(
      'users',
      {
        'username': _defaultAdminUsername,
        'name': 'Administrador',
        'password_hash': _hashPassword(_defaultAdminUsername, _defaultAdminPassword),
        'role': 'admin',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _createStoresTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stores (
        id TEXT PRIMARY KEY,
        owner_username TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        address TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        photo_path TEXT
      )
    ''');
  }

  String _hashPassword(String username, String password) {
    // Hash SHA-256 combinado con el usuario, para que dos cuentas con la
    // misma contraseña no guarden el mismo hash.
    final bytes = utf8.encode('tiendacerca::$username::$password');
    return sha256.convert(bytes).toString();
  }

  // ---------------------------------------------------------------------
  // Favoritos
  // ---------------------------------------------------------------------

  Future<Set<String>> readFavoriteIds() async {
    final db = await _database;
    final rows = await db.query('favorites');
    return rows.map((row) => row['offer_id'] as String).toSet();
  }

  Future<void> insertFavorite(String offerId) async {
    final db = await _database;
    await db.insert(
      'favorites',
      {'offer_id': offerId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFavorite(String offerId) async {
    final db = await _database;
    await db.delete('favorites', where: 'offer_id = ?', whereArgs: [offerId]);
  }

  // ---------------------------------------------------------------------
  // Ofertas de "mi tienda" (panel de comerciante)
  // ---------------------------------------------------------------------

  Future<List<Offer>> readMerchantOffers() async {
    final db = await _database;
    final rows = await db.query('merchant_offers');
    return rows.map(_offerFromRow).toList();
  }

  Future<void> insertMerchantOffer(Offer offer) async {
    final db = await _database;
    await db.insert(
      'merchant_offers',
      _offerToRow(offer),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMerchantOffer(Offer offer) async {
    final db = await _database;
    await db.update(
      'merchant_offers',
      _offerToRow(offer),
      where: 'id = ?',
      whereArgs: [offer.id],
    );
  }

  Future<void> deleteMerchantOffer(String offerId) async {
    final db = await _database;
    await db.delete('merchant_offers', where: 'id = ?', whereArgs: [offerId]);
  }

  // ---------------------------------------------------------------------
  // Cuentas de usuario y sesión
  // ---------------------------------------------------------------------

  /// Crea una cuenta nueva. Devuelve `null` si todo salió bien, o un
  /// mensaje de error (por ejemplo, si el usuario ya existe) para
  /// mostrarlo tal cual en la pantalla de registro.
  Future<String?> registerUser({
    required String name,
    required String username,
    required String password,
    required String role,
  }) async {
    final db = await _database;
    final existing = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (existing.isNotEmpty) {
      return 'Ese nombre de usuario ya está en uso, elige otro.';
    }
    await db.insert('users', {
      'username': username,
      'name': name,
      'password_hash': _hashPassword(username, password),
      'role': role,
    });
    return null;
  }

  /// Revisa usuario y contraseña contra la cuenta guardada. Devuelve
  /// `{'username': ..., 'name': ..., 'role': ...}` si son correctos, o
  /// `null` si el usuario no existe o la contraseña no coincide.
  Future<Map<String, String>?> login(String username, String password) async {
    final db = await _database;
    final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    if (row['password_hash'] != _hashPassword(username, password)) return null;
    return {
      'username': username,
      'name': row['name'] as String,
      'role': row['role'] as String,
    };
  }

  /// Devuelve la cuenta de la sesión recordada (si alguien había iniciado
  /// sesión antes y no la cerró), o `null`.
  Future<Map<String, String>?> readSessionUser() async {
    final db = await _database;
    final sessionRows = await db.query('app_session', where: 'id = 1');
    if (sessionRows.isEmpty) return null;
    final username = sessionRows.first['username'] as String;

    final userRows = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (userRows.isEmpty) return null; // la cuenta ya no existe
    final row = userRows.first;
    return {
      'username': username,
      'name': row['name'] as String,
      'role': row['role'] as String,
    };
  }

  Future<void> saveSessionUsername(String username) async {
    final db = await _database;
    await db.insert(
      'app_session',
      {'id': 1, 'username': username},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearSession() async {
    final db = await _database;
    await db.delete('app_session', where: 'id = 1');
  }

  // ---------------------------------------------------------------------
  // Tiendas registradas por cada Dueño de tienda
  // ---------------------------------------------------------------------

  /// Guarda la tienda de un Dueño de tienda. El id siempre tiene la forma
  /// `store-<username>` (una tienda por cuenta); si ya existe, se reemplaza.
  Future<void> insertStore(Map<String, Object?> row) async {
    final db = await _database;
    await db.insert('stores', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> readAllStores() async {
    final db = await _database;
    return db.query('stores');
  }

  Future<Map<String, Object?>?> readStoreById(String id) async {
    final db = await _database;
    final rows = await db.query('stores', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Offer _offerFromRow(Map<String, Object?> row) {
    return Offer(
      id: row['id'] as String,
      storeId: row['store_id'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      price: (row['price'] as num).toDouble(),
      oldPrice: (row['old_price'] as num).toDouble(),
      stockText: row['stock_text'] as String,
      description: row['description'] as String,
      swatchColorValue: row['swatch_color_value'] as int,
      paused: (row['paused'] as int) == 1,
      photoPath: row['photo_path'] as String?,
    );
  }

  Map<String, Object?> _offerToRow(Offer offer) {
    return {
      'id': offer.id,
      'store_id': offer.storeId,
      'name': offer.name,
      'category': offer.category,
      'price': offer.price,
      'old_price': offer.oldPrice,
      'stock_text': offer.stockText,
      'description': offer.description,
      'swatch_color_value': offer.swatchColorValue,
      'paused': offer.paused ? 1 : 0,
      'photo_path': offer.photoPath,
    };
  }
}
