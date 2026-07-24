import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/grid_columns_provider.dart';
import 'providers/listings_refresh_provider.dart';
import 'providers/conversations_refresh_provider.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  runApp(const BootstrapApp());
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => GridColumnsProvider()),
        ChangeNotifierProvider(create: (_) => ListingsRefreshProvider()),
        ChangeNotifierProvider(create: (_) => ConversationsRefreshProvider()),
      ],
      child: MaterialApp.router(
        title: 'Dorm Exchange',
        theme: appTheme,
        routerConfig: createAppRouter(authProvider),
      ),
    );
  }
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  AuthProvider? _authProvider;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Firebase init timed out'),
      );

      if (!mounted) return;
      setState(() {
        _authProvider = AuthProvider();
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'app_startup',
          context: ErrorDescription('during app bootstrap'),
        ),
      );
      if (!mounted) return;
      setState(() {
        _startupError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authProvider != null) {
      return MyApp(authProvider: _authProvider!);
    }
    if (_startupError != null) {
      return StartupErrorApp(error: _startupError!);
    }
    return const StartupLoadingApp();
  }
}

class StartupLoadingApp extends StatelessWidget {
  const StartupLoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  final Object error;

  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dorm Exchange',
      home: Scaffold(
        body: SafeArea(
          minimum: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text(
                  'App failed to start.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
