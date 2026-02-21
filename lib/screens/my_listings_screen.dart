import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/listing.dart';
import '../providers/grid_columns_provider.dart';
import '../providers/listings_refresh_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_container.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<Listing> _listings = [];
  bool _isLoading = true;
  String? _error;
  ListingsRefreshProvider? _refreshProvider;
  bool _listenerAdded = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerAdded) {
      _refreshProvider = context.read<ListingsRefreshProvider>();
      _refreshProvider!.addListener(_onRefreshRequested);
      _listenerAdded = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshProvider?.removeListener(_onRefreshRequested);
    super.dispose();
  }

  List<Listing> get _activeListings =>
      _listings.where((l) => l.status == 'active').toList();
  List<Listing> get _soldListings =>
      _listings.where((l) => l.status == 'sold' || l.status == 'taken').toList();

  void _onRefreshRequested() => _fetch();

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _api.getMeWithListings();
      if (mounted) {
        setState(() {
          _listings = result.listings;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load your listings';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markStatus(Listing listing, String status, {String? successMessage}) async {
    try {
      await _api.updateListingStatus(listing.id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage ?? 'Marked as $status'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetch();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _deleteListing(Listing listing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove listing?'),
        content: Text('This will remove "${listing.title}" from the marketplace.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _markStatus(listing, 'deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me'),
        backgroundColor: const Color(0xFF0F172A).withOpacity(0.85),
        bottom: (_isLoading && _listings.isEmpty) || (_error != null && _listings.isEmpty)
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF38BDF8),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Active (${_activeListings.length})'),
                  Tab(text: 'Sold (${_soldListings.length})'),
                ],
              ),
        actions: [
          Consumer<GridColumnsProvider>(
            builder: (context, grid, _) => IconButton(
              tooltip: 'Layout: ${grid.columns} column${grid.columns > 1 ? 's' : ''}',
              icon: Icon(
                grid.columns == 1 ? Icons.view_list : (grid.columns == 2 ? Icons.view_module : Icons.grid_view),
                color: Colors.white70,
              ),
              onPressed: () => grid.cycleColumns(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: const Color(0xFF38BDF8),
        child: _isLoading && _listings.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
            : _error != null && _listings.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.8))),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabBody(_activeListings),
                      _buildTabBody(_soldListings),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTabBody(List<Listing> listings) {
    if (listings.isNotEmpty) {
      return Consumer<GridColumnsProvider>(
        builder: (context, grid, _) {
          final cols = grid.columns;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: cols == 1 ? 2.8 : (cols == 2 ? 0.78 : 0.72),
            ),
            itemCount: listings.length,
            itemBuilder: (context, i) {
              final listing = listings[i];
              return _MyListingGridTile(
                listing: listing,
                columns: cols,
                onTap: () => context.push('/listing/${listing.id}').then((_) => _fetch()),
                onMarkSold: () => _markStatus(listing, 'sold'),
                onMarkTaken: () => _markStatus(listing, 'taken'),
                onRelist: () => _markStatus(listing, 'active', successMessage: 'Relisted'),
                onDelete: () => _deleteListing(listing),
              );
            },
          );
        },
      );
    }
    final isActiveTab = identical(listings, _activeListings);
    final showFirstTimeEmpty = _listings.isEmpty && isActiveTab;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - kToolbarHeight - kBottomNavigationBarHeight - 120,
          child: showFirstTimeEmpty ? _buildFirstTimeEmptyState() : _buildEmptyTabState(isActiveTab),
        ),
      ],
    );
  }

  Widget _buildFirstTimeEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "You don't have any listings...YET",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.12),
                    letterSpacing: 0.5,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              borderRadius: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/create').then((_) => _fetch()),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Post your first listing',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTabState(bool isActiveTab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActiveTab ? Icons.inventory_2_outlined : Icons.check_circle_outline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isActiveTab ? 'No active listings' : 'No sold or taken listings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isActiveTab
                  ? 'Your active listings will appear here.'
                  : 'Items you mark as sold or taken will appear here.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}

class _MyListingGridTile extends StatelessWidget {
  final Listing listing;
  final int columns;
  final VoidCallback onTap;
  final VoidCallback onMarkSold;
  final VoidCallback onMarkTaken;
  final VoidCallback? onRelist;
  final VoidCallback onDelete;

  const _MyListingGridTile({
    required this.listing,
    required this.columns,
    required this.onTap,
    required this.onMarkSold,
    required this.onMarkTaken,
    this.onRelist,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = listing.status == 'active';
    final isWide = columns == 1;

    return GlassContainer(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: isWide ? 3 : 2,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                        ? Image.network(
                            listing.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.more_vert, size: 18, color: Colors.white),
                      ),
                      onSelected: (v) {
                        if (v == 'sold') onMarkSold();
                        if (v == 'taken') onMarkTaken();
                        if (v == 'relist') onRelist?.call();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        if (isActive) const PopupMenuItem(value: 'sold', child: Text('Mark as sold')),
                        if (isActive) const PopupMenuItem(value: 'taken', child: Text('Mark as taken')),
                        if ((listing.status == 'sold' || listing.status == 'taken') && onRelist != null)
                          const PopupMenuItem(value: 'relist', child: Text('Relist item')),
                        const PopupMenuItem(value: 'delete', child: Text('Remove listing')),
                      ],
                    ),
                  ),
                  if (!isActive)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.status,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.isFree ? 'FREE' : '\$${listing.price?.toStringAsFixed(0) ?? '0'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white.withOpacity(0.06),
      child: Icon(Icons.image_not_supported, color: Colors.white.withOpacity(0.3), size: 32),
    );
  }
}
