import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/chat_screen.dart';
import '../screens/create_listing_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/listing_detail_screen.dart';
import '../screens/select_listing_to_message_screen.dart';
import '../login_screen.dart';
import '../main_shell.dart';
import '../screens/notification_settings_screen.dart';
import '../screens/settings_screen.dart';

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      if (authProvider.isLoading) return null;
      final isLoggingIn = state.matchedLocation == '/login';
      if (!authProvider.isAuthenticated && !isLoggingIn) return '/login';
      if (authProvider.isAuthenticated && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const MainShell(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, __) => const CreateListingScreen(),
          ),
          GoRoute(
            path: 'listing/:id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return ListingDetailScreen(listingId: id);
            },
          ),
          GoRoute(
            path: 'chat/:id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return ChatScreen(conversationId: id);
            },
          ),
          GoRoute(
            path: 'select-listing',
            builder: (_, __) => const SelectListingToMessageScreen(),
          ),
          GoRoute(
            path: 'edit-profile',
            builder: (_, __) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (_, __) => const ProfileSettingsScreen(),
          ),
          GoRoute(
            path: 'exchanges',
            builder: (_, __) => const ExchangesScreen(),
          ),
          GoRoute(
            path: 'saved',
            builder: (_, __) => const SavedScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (_, __) => const NotificationCenterScreen(),
          ),
        ],
      ),
    ],
  );
}
