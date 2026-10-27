// Autor: Roberto
// Punto de entrada de la app: arranca TiendaCerca con el estado global
// (AppState) y el tema de la aplicación.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/root_shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TiendaCercaApp());
}

class TiendaCercaApp extends StatelessWidget {
  const TiendaCercaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()
        ..loadLocation()
        ..loadFromDatabase(),
      child: MaterialApp(
        title: 'TiendaCerca',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const RootShell(),
      ),
    );
  }
}
