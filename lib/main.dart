import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/grid_columns_provider.dart';
import 'providers/listings_refresh_provider.dart';
import 'providers/conversations_refresh_provider.dart';
import 'auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GridColumnsProvider()),
        ChangeNotifierProvider(create: (_) => ListingsRefreshProvider()),
        ChangeNotifierProvider(create: (_) => ConversationsRefreshProvider()),
      ],
      child: MaterialApp(
        title: 'Dorm Exchange',
        theme: appTheme,
        home: const AuthGate(),
      ),
    );
  }
}
