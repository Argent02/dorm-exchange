import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/my_listings_screen.dart';
import 'screens/create_listing_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/glass_container.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const InboxScreen(),
      const MyListingsScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      floatingActionButton: (_index == 1 || _index == 2 || _index == 3) ? null : GlassContainer(
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 24),
        borderRadius: 28,
        blur: 12,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openCreateListing(context),
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _GlassBottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  void _openCreateListing(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateListingScreen(),
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        borderRadius: 28,
        blur: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, 0, Icons.home_outlined, Icons.home, 'Home'),
            _navItem(context, 1, Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages'),
            const SizedBox(width: 48),
            _navItem(context, 2, Icons.inventory_2_outlined, Icons.inventory_2, 'Me'),
            _navItem(context, 3, Icons.settings_outlined, Icons.settings, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int i,
    IconData outline,
    IconData filled,
    String label,
  ) {
    final selected = index == i;
    return InkWell(
      onTap: () => onTap(i),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? filled : outline,
              size: 22,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white.withValues(alpha: 0.6),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
