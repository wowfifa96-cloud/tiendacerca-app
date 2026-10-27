// Autor: Roberto
// Pruebas unitarias de los modelos de datos (Offer, UserRole).
import 'package:flutter_test/flutter_test.dart';

import 'package:ferrecerca_app/models/offer.dart';
import 'package:ferrecerca_app/models/user_role.dart';

void main() {
  group('Offer', () {
    const offer = Offer(
      id: 'o1',
      storeId: 's1',
      name: 'Taladro de prueba',
      category: 'Herramientas',
      price: 75,
      oldPrice: 100,
      stockText: 'Disponible',
      description: 'Oferta de prueba',
      swatchColorValue: 0xFF000000,
    );

    test('priceLabel y oldPriceLabel muestran "Bs <monto>" sin decimales', () {
      expect(offer.priceLabel, 'Bs 75');
      expect(offer.oldPriceLabel, 'Bs 100');
    });

    test('discountLabel calcula bien el porcentaje de descuento', () {
      expect(offer.discountPercent, 25);
      expect(offer.discountLabel, '-25%');
    });

    test('discountPercent no revienta si oldPrice es 0 (evita división entre cero)', () {
      const sinPrecioViejo = Offer(
        id: 'o2',
        storeId: 's1',
        name: 'Sin precio anterior',
        category: 'Herramientas',
        price: 50,
        oldPrice: 0,
        stockText: 'Disponible',
        description: 'desc',
        swatchColorValue: 0xFF000000,
      );
      expect(sinPrecioViejo.discountPercent, 0);
    });

    test('copyWith solo cambia los campos indicados y conserva el resto', () {
      final pausada = offer.copyWith(paused: true);
      expect(pausada.paused, isTrue);
      expect(pausada.name, offer.name);
      expect(pausada.price, offer.price);
      expect(pausada.id, offer.id);
    });

    test('copyWith no puede usarse para borrar la foto (se documenta el por qué)', () {
      // copyWith(photoPath: null) no borra la foto: `?? this.photoPath`
      // no distingue "no tocar" de "borrar".
      const conFoto = Offer(
        id: 'o3',
        storeId: 's1',
        name: 'Con foto',
        category: 'Herramientas',
        price: 50,
        oldPrice: 50,
        stockText: 'Disponible',
        description: 'desc',
        swatchColorValue: 0xFF000000,
        photoPath: '/ruta/foto.jpg',
      );
      final intentoDeBorrar = conFoto.copyWith(photoPath: null);
      expect(intentoDeBorrar.photoPath, '/ruta/foto.jpg');
    });
  });

  group('UserRole (semana 7 — tipos de usuario)', () {
    test('cada rol tiene su propia etiqueta', () {
      expect(UserRole.cliente.label, 'Cliente');
      expect(UserRole.dueno.label, 'Dueño de tienda');
      expect(UserRole.admin.label, 'Administrador');
    });

    test('UserRole.values.byName reconstruye el rol guardado como texto en SQLite', () {
      expect(UserRole.values.byName('cliente'), UserRole.cliente);
      expect(UserRole.values.byName('dueno'), UserRole.dueno);
      expect(UserRole.values.byName('admin'), UserRole.admin);
    });
  });
}
