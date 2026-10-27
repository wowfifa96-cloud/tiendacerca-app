// Autor: Roberto
// Pruebas de navegación por tipo de usuario (Cliente, Dueño de tienda,
// Administrador). No se usa pumpAndSettle() tras entrar porque la pantalla
// de carga anima indefinidamente; se espera con pump(Duration) fijo.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ferrecerca_app/data/database_helper.dart';
import 'package:ferrecerca_app/main.dart';

Future<void> _pumpAppAndWaitForLoad(WidgetTester tester) async {
  await tester.pumpWidget(const TiendaCercaApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Base de datos limpia en cada corrida: si no, los usuarios de prueba
    // (cliente_test, dueno_test) ya existirían y el registro fallaría.
    final dbPath = await databaseFactory.getDatabasesPath();
    final dbFile = File('$dbPath/tiendacerca.db');
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
  });

  setUp(() async {
    // Evita que una sesión guardada por una prueba anterior afecte esta.
    await DatabaseHelper.instance.clearSession();
  });

  group('Semana 8 - login real (usuario y contraseña)', () {
    testWidgets('sin sesión iniciada se muestra el login con usuario y contraseña', (tester) async {
      await _pumpAppAndWaitForLoad(tester);

      expect(find.byKey(const Key('login_username')), findsOneWidget);
      expect(find.byKey(const Key('login_password')), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('¿No tienes cuenta? Crea una'), findsOneWidget);
    });

    testWidgets('registrarse como Cliente: solo ve Buscar, Favoritos y Perfil', (tester) async {
      await _pumpAppAndWaitForLoad(tester);

      await tester.tap(find.text('¿No tienes cuenta? Crea una'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_name')), 'Cliente de Prueba');
      await tester.enterText(find.byKey(const Key('register_username')), 'cliente_test');
      await tester.enterText(find.byKey(const Key('register_password')), '1234');
      await tester.enterText(find.byKey(const Key('register_confirm')), '1234');

      await tester.tap(find.text('Crear cuenta y entrar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Buscar'), findsOneWidget);
      expect(find.text('Favoritos'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Mi tienda'), findsNothing);
      expect(find.text('Admin'), findsNothing);
    });

    testWidgets(
        'registrarse como Dueño de tienda: registra su propia tienda (ubicación y foto) y puede publicar ofertas en ella',
        (tester) async {
      await _pumpAppAndWaitForLoad(tester);

      await tester.tap(find.text('¿No tienes cuenta? Crea una'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_name')), 'Dueño de Prueba');
      await tester.enterText(find.byKey(const Key('register_username')), 'dueno_test');
      await tester.enterText(find.byKey(const Key('register_password')), '1234');
      await tester.enterText(find.byKey(const Key('register_confirm')), '1234');
      await tester.tap(find.byKey(const Key('register_role_dueno')));
      await tester.pump();

      expect(find.byKey(const Key('register_store_name')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('register_store_name')), 'Mi Tienda de Prueba');
      await tester.enterText(find.byKey(const Key('register_store_address')), 'Calle de Prueba #123');

      await tester.tap(find.text('Crear cuenta y entrar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mi tienda'), findsOneWidget);
      expect(find.text('Admin'), findsNothing);

      await tester.tap(find.text('Mi tienda'));
      await tester.pump();

      expect(find.text('Publicar oferta'), findsOneWidget);
      expect(find.text('Taladro percutor 650W'), findsNothing);

      await tester.tap(find.text('Publicar oferta'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('publish_offer_name')), 'Oferta de Prueba');
      await tester.enterText(find.byKey(const Key('publish_offer_price')), '50');
      await tester.tap(find.text('Publicar oferta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Oferta de Prueba'), findsOneWidget);
    });

    testWidgets(
        'iniciar sesión con la cuenta admin sembrada entra como Administrador y puede moderar ofertas de cualquier tienda',
        (tester) async {
      await _pumpAppAndWaitForLoad(tester);

      await tester.enterText(find.byKey(const Key('login_username')), 'admin');
      await tester.enterText(find.byKey(const Key('login_password')), 'admin123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Mi tienda'), findsNothing);

      await tester.tap(find.text('Admin'));
      await tester.pump();

      expect(find.text('Todas las tiendas'), findsOneWidget);
      expect(find.text('Mi Tienda de Prueba'), findsOneWidget);
      expect(find.text('Oferta de Prueba'), findsOneWidget);
    });

    testWidgets('contraseña incorrecta muestra un error y no entra', (tester) async {
      await _pumpAppAndWaitForLoad(tester);

      await tester.enterText(find.byKey(const Key('login_username')), 'admin');
      await tester.enterText(find.byKey(const Key('login_password')), 'una-contraseña-equivocada');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
      expect(find.byKey(const Key('login_username')), findsOneWidget);
    });

    testWidgets('cerrar sesión desde el Perfil regresa a la pantalla de login', (tester) async {
      await _pumpAppAndWaitForLoad(tester);

      await tester.enterText(find.byKey(const Key('login_username')), 'admin');
      await tester.enterText(find.byKey(const Key('login_password')), 'admin123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Perfil'));
      await tester.pump();

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('login_username')), findsOneWidget);
    });
  });
}
