# DormExchange Design System

This document describes the design system and UX standards for the app.

## Design Tokens

### Spacing (`AppSpacing`)
- `xxs`: 4pt
- `xs`: 8pt
- `sm`: 12pt
- `md`: 16pt
- `lg`: 20pt
- `xl`: 24pt
- `xxl`: 32pt

### Border Radius (`AppRadius`)
- `sm`: 8pt
- `md`: 12pt
- `lg`: 16pt
- `xl`: 20pt
- `full`: pill/circle

### Colors (`AppColors` extension on `ColorScheme`)
- `onSurfaceMuted` – muted text
- `placeholderIcon` – placeholder icons
- `surfaceOverlay` – subtle overlays
- `surfaceOverlayStrong` – stronger overlays
- `accentMuted` – softer accent
- `errorColor` – error states
- `successColor` – success feedback

## Shared Components

| Component | Path | Use |
|-----------|------|-----|
| `AppFilterChip` | `widgets/filter_chip.dart` | Category/filter selection |
| `EmptyState` | `widgets/empty_state.dart` | Empty lists with icon, title, optional action |
| `ErrorState` | `widgets/error_state.dart` | Error display with retry |
| `ImagePlaceholder` | `widgets/image_placeholder.dart` | Missing/failed images |
| `GlassContainer` | `widgets/glass_container.dart` | Frosted glass card (use sparingly – expensive) |

## Navigation

- **Tabs**: Home, Messages, Listings, Settings
- **FAB**: Create listing (visible on Home and Listings tabs)
- **CreateListingScreen**: Prompts to discard unsaved changes on back
- **SelectListingToMessageScreen**: Uses `push` (not `pushReplacement`) so back from Chat returns to listing picker

## User Flows

### Create listing
1. Tap FAB on Home or Listings
2. Add photo, title, description, price/category
3. Post → success SnackBar, pop to previous
4. Back with unsaved changes → discard confirmation dialog

### Browse & save
1. Home → filter chips (All, Free, Furniture, etc.) → tap listing
2. Listing detail → Save/unsave (SnackBar feedback)
3. Message seller → Chat

### Messaging
1. Messages tab → + to start new → pick listing → Chat
2. Back from Chat returns to listing picker (can choose another)
3. Tap existing conversation → Chat

## Routing (GoRouter)

All navigation uses `go_router`. Routes:

| Path | Screen |
|------|--------|
| `/login` | LoginScreen |
| `/` | MainShell (tabs) |
| `/create` | CreateListingScreen |
| `/listing/:id` | ListingDetailScreen |
| `/chat/:id` | ChatScreen |
| `/select-listing` | SelectListingToMessageScreen |
| `/edit-profile` | EditProfileScreen |
| `/profile` | ProfileSettingsScreen |
| `/exchanges` | ExchangesScreen |
| `/saved` | SavedScreen |
| `/notifications` | NotificationCenterScreen |

Auth redirect: unauthenticated users go to `/login`; authenticated users on `/login` go to `/`.

## Future Improvements
- **Lazy tabs**: Build only the active tab to improve startup performance
- **CachedNetworkImage**: Add for listing images
- **Accessibility**: Add `Semantics` and `semanticsLabel` on interactive elements
- **Reduce GlassContainer**: Use solid `surfaceContainerHighest` for listing tiles
