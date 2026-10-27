import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'merchant_dashboard_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

// Autor: Roberto
// Punto de entrada de la navegación principal: muestra el login si no hay
// sesión iniciada, o las pestañas según el rol de la cuenta.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.loadingDataSource) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!appState.isLoggedIn) {
      return const LoginScreen();
    }
    return _MainTabs(role: appState.currentRole!);
  }
}

// Las pestañas varían según el rol de la cuenta.
class _MainTabs extends StatefulWidget {
  final UserRole role;
  const _MainTabs({required this.role});

  @override
  State<_MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<_MainTabs> {
  int _index = 0;

  List<Widget> _tabsFor(UserRole role) {
    switch (role) {
      case UserRole.cliente:
        return const [SearchScreen(), FavoritesScreen(), ProfileScreen()];
      case UserRole.dueno:
        return const [SearchScreen(), FavoritesScreen(), MerchantDashboardScreen(), ProfileScreen()];
      case UserRole.admin:
        return const [SearchScreen(), AdminDashboardScreen(), ProfileScreen()];
    }
  }

  List<NavigationDestination> _destinationsFor(UserRole role) {
    const profile = NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil');
    const buscar = NavigationDestination(icon: Icon(Icons.search), label: 'Buscar');
    const favoritos = NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Favoritos');
    switch (role) {
      case UserRole.cliente:
        return const [buscar, favoritos, profile];
      case UserRole.dueno:
        return const [
          buscar,
          favoritos,
          NavigationDestination(icon: Icon(Icons.store_outlined), label: 'Mi tienda'),
          profile,
        ];
      case UserRole.admin:
        return const [
          buscar,
          NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
          profile,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabsFor(widget.role);
    final destinations = _destinationsFor(widget.role);
    // Evita apuntar a una pestaña fuera de rango si el nuevo rol tiene menos.
    if (_index >= tabs.length) {
      _index = 0;
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: tabs),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.12),
        destinations: destinations,
      ),
    );
  }
}
