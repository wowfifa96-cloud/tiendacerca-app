import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

// Autor: Roberto
// Pantalla de inicio de sesión: valida usuario y contraseña contra las
// cuentas guardadas en SQLite.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await context.read<AppState>().login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'Usuario o contraseña incorrectos.';
      });
      return;
    }
    // No hace falta navegar manualmente: RootShell está escuchando
    // AppState.isLoggedIn y cambia de pantalla solo.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 18),
              Text('TiendaCerca', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              const Text(
                'Inicia sesión para continuar',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
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
                key: const Key('login_username'),
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Escribe tu usuario' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('login_password'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Escribe tu contraseña' : null,
              ),
              const SizedBox(height: 20),
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
                      : const Text('Entrar'),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                  child: const Text('¿No tienes cuenta? Crea una'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
