// Autor: Roberto
// Los tres tipos de cuenta de la app: cada uno ve una navegación distinta
// según su rol.
enum UserRole {
  cliente,
  dueno,
  admin;

  String get label {
    switch (this) {
      case UserRole.cliente:
        return 'Cliente';
      case UserRole.dueno:
        return 'Dueño de tienda';
      case UserRole.admin:
        return 'Administrador';
    }
  }

  String get description {
    switch (this) {
      case UserRole.cliente:
        return 'Busca tiendas cercanas y guarda tus ofertas favoritas.';
      case UserRole.dueno:
        return 'Publica y administra las ofertas de tu propia tienda.';
      case UserRole.admin:
        return 'Supervisa todas las tiendas y ofertas de la plataforma.';
    }
  }
}
