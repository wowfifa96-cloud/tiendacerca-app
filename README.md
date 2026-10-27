# TiendaCerca — proyecto Flutter

App de práctica: busca tiendas cercanas (ferreterías, abarrotes, ropa,
farmacias, electrónica, restaurantes, entre otras) por geolocalización real
y permite que cada tienda publique ofertas, con foto incluida. El catálogo
general de tiendas sigue siendo de ejemplo (mock), pensado para
reemplazarse después por un backend real — pero todo lo que el usuario
realmente hace dentro de la app (sus favoritos, el rol con el que entra,
las ofertas que publica en "Mi tienda") ya se guarda de verdad en una base
de datos SQLite local (ver sección "Base de datos local" más abajo).

## Qué incluye

- Tres tipos de usuario (Cliente, Dueño de tienda, Administrador), cada
  uno con su propia navegación — ver sección "Tipos de usuario" más abajo.
- Búsqueda y filtro de tiendas por categoría de comercio, con mapa real
  (OpenStreetMap, sin necesitar API key) y lista ordenada por distancia
  usando tu ubicación GPS de verdad (paquete `geolocator`).
- Detalle de tienda (info, horario, botones "Cómo llegar" y "Llamar"
  que abren Maps/el marcador y el discador del teléfono).
- Detalle de oferta, con favoritos.
- Panel de "Mi tienda" (rol Dueño de tienda): estadísticas, publicar una
  oferta nueva con foto real (cámara o galería), editarla, pausarla o
  eliminarla.
- Panel de Administrador: ve el catálogo completo de tiendas de la
  plataforma y puede pausar o eliminar cualquier oferta publicada (no
  solo las propias), para moderación.
- Manejo de estado con `provider` (ChangeNotifier) — la forma más común
  de empezar en Flutter antes de pasar a Riverpod/Bloc si lo necesitas.
- Pruebas automatizadas con `flutter_test` (modelos y navegación por rol)
  — ver sección "Pruebas" más abajo.

## 1. Preparar el proyecto

Este .zip trae solo el código Dart (`lib/`) y `pubspec.yaml` — le faltan
las carpetas nativas (`android/`, `ios/`, etc.) porque esas las genera el
propio Flutter. Pasos:

```bash
# 1. Crea un proyecto Flutter nuevo y vacío
flutter create ferrecerca_app
cd ferrecerca_app

# 2. Reemplaza el pubspec.yaml y la carpeta lib/ generados
#    por los de este .zip (sobrescribe cuando te lo pida)

# 3. Instala las dependencias
flutter pub get
```

## 2. Permisos

`flutter create` genera `android/` e `ios/` sin permisos de ubicación ni
de cámara — hay que agregarlos a mano.

**Android** — en `android/app/src/main/AndroidManifest.xml`, dentro de
`<manifest>` (antes de `<application>`):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

**iOS** — en `ios/Runner/Info.plist`, dentro del `<dict>` principal:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>TiendaCerca usa tu ubicación para mostrarte las tiendas más cercanas.</string>
<key>NSCameraUsageDescription</key>
<string>TiendaCerca usa la cámara para que le tomes una foto a tu oferta.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>TiendaCerca necesita acceso a tus fotos para elegir la imagen de una oferta.</string>
```

Sin el permiso de ubicación, `geolocator` va a fallar al pedir permiso (la
app igual funciona: cae de respaldo a un punto fijo en el centro de La
Paz). Sin el de cámara, `image_picker` no va a poder tomar fotos (sí
podría seguir funcionando para elegir de la galería, según el sistema).

## 3. Correr la app

```bash
flutter run
```

Elige un emulador o conecta tu celular por USB (con depuración USB
activada). La primera vez Android/iOS te va a pedir el permiso de
ubicación — acéptalo para ver las distancias reales.

La app solo se ha probado en Android (celular físico y varios emuladores
con Android 14 y 16). Como es Flutter, en teoría compila también para
iOS/web/escritorio, pero no se ha verificado todavía.

## 4. Tipos de usuario

Al abrir la app por primera vez aparece una pantalla de login donde se
elige con qué tipo de usuario entrar:

| Rol | Qué puede hacer | Pestañas |
|---|---|---|
| Cliente | Buscar tiendas, ver ofertas, guardar favoritos | Buscar, Favoritos, Perfil |
| Dueño de tienda | Todo lo del Cliente + publicar/editar/pausar/eliminar ofertas de su tienda | Buscar, Favoritos, Mi tienda, Perfil |
| Administrador | Ve todas las tiendas y puede pausar/eliminar cualquier oferta publicada | Buscar, Admin, Perfil |

Desde la semana 8 el login es real: hay que crear una cuenta (usuario y
contraseña, guardados con hash en SQLite) desde "Crear cuenta", eligiendo
si entras como Cliente o Dueño de tienda. El rol Administrador no se
registra: ya existe una cuenta sembrada por defecto (usuario `admin`,
contraseña `admin123`) que entra por el mismo formulario. La sesión se
recuerda entre reinicios (tabla `app_session`) hasta que se cierre sesión
desde la pestaña Perfil.

Al registrarte como Dueño de tienda eliges, además, el nombre, la
categoría, la dirección, una foto (opcional) y la ubicación real de tu
tienda tocando un mapa — esa es la tienda que administras en "Mi tienda",
y aparece de verdad en las búsquedas de los Clientes y en el panel del
Administrador (tabla `stores` en SQLite). Ya no todos los dueños comparten
la misma tienda de ejemplo.

## 5. Pruebas

```bash
flutter test
```

- `test/models_test.dart` — pruebas unitarias de `Offer` (cálculo de
  precio/descuento) y `UserRole`.
- `test/role_navigation_test.dart` — pruebas de interfaz: registrarse como
  Cliente y como Dueño de tienda (con su propia tienda y una oferta
  publicada), iniciar sesión con la cuenta admin sembrada, una contraseña
  incorrecta, y cerrar sesión. Usa `sqflite_common_ffi` para correr SQLite
  de verdad dentro de `flutter test`.
- `test/widget_test.dart` — prueba mínima de que la app arranca.

## Estructura del código

```
lib/
  main.dart                       # arranque + Provider + tema
  theme/app_theme.dart            # colores y estilos (todo centralizado acá)
  models/                         # Store, Offer, UserRole (clases de datos)
  data/mock_data.dart             # tiendas y ofertas de ejemplo (catálogo)
  data/database_helper.dart       # base de datos local SQLite (sesión, favoritos, ofertas propias)
  services/location_service.dart  # wrapper de geolocator (permisos, distancia)
  state/app_state.dart            # ChangeNotifier: sesión/rol, filtros, favoritos, ubicación, fuente de datos
  widgets/                        # piezas reutilizables (tarjetas, chips, mapa)
  screens/                        # una pantalla por archivo (login, perfil, admin, comprador, comerciante)
```

## Base de datos local

Desde la semana 6 de la materia, la app usa una base de datos **SQLite**
local (paquete `sqflite`, manejada en `lib/data/database_helper.dart`)
para guardar lo que el usuario realmente cambia:

- las **cuentas** (usuario, nombre, contraseña con hash y rol — tabla
  `users`, semana 8) y la **sesión** (qué cuenta sigue con la sesión
  abierta — tabla `app_session`)
- las **tiendas** que registra cada Dueño de tienda (nombre, categoría,
  dirección, ubicación y foto — tabla `stores`, semana 8)
- tus **favoritos** (tabla `favorites`)
- las **ofertas de "Mi tienda"** que publicas, editas, pausas o eliminas
  (tabla `merchant_offers`, con la tienda dueña de cada una)

`AppState.loadFromDatabase()` lee esas tablas al abrir la app. Cada vez
que cambias algo — te registras, inicias o cierras sesión, marcas un
favorito, publicas o editas una oferta — `AppState` escribe el cambio en
la base de datos. Si esa escritura falla (por ejemplo corriendo en una
plataforma de escritorio sin soporte de SQLite), la app no se cae: sigue
funcionando con los datos en memoria y muestra un aviso en el panel de
comerciante.

El catálogo de tiendas (`mock_data.dart`) sigue siendo de ejemplo a
propósito — ese es el que se reemplazaría por llamadas a un backend/API
real más adelante.

## Ideas para seguir practicando

- Conectar un backend remoto real (Firebase, Supabase, o tu propia API)
  para el catálogo de tiendas — hoy solo los datos propios del usuario
  (sesión, favoritos, ofertas publicadas) están persistidos localmente.
- Notificaciones push cuando una tienda que sigues publica una oferta.
- Dejar que un Dueño de tienda edite su tienda después de registrarla
  (hoy el nombre, la ubicación y la foto se fijan al crear la cuenta).
- Más pruebas automatizadas: hoy cubren los modelos y la navegación por
  rol, pero no todavía los flujos de publicar/editar/eliminar una oferta
  de punta a punta.

## Si `flutter pub get` o la compilación fallan

- Este proyecto fue escrito para un Flutter relativamente reciente
  (estable, 2025 en adelante). Si ves un error de tipo no encontrado
  cerca de `CardThemeData` o `ColorScheme.fromSeed`, corre
  `flutter upgrade` y probá de nuevo.
- Si `flutter pub get` no encuentra alguna versión exacta de un
  paquete, abrí `pubspec.yaml` y bajá el número de versión (por
  ejemplo `^13.0.2` a `^13.0.0`) o corré
  `flutter pub upgrade --major-versions`.
