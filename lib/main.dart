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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authProvider = AuthProvider();

  runApp(MyApp(authProvider: authProvider));
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
