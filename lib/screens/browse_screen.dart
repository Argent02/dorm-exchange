import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../providers/grid_columns_provider.dart';
import '../providers/listings_refresh_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_container.dart';
import 'listing_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final ApiService _api = ApiService();
  final _searchController = TextEditingController();

  List<Listing> _listings = [];
  int _total = 0;
  bool _isLoading = true;
  String? _error;
  String? _searchQuery;
  String? _categoryFilter;
  bool? _freeOnly;
  ListingsRefreshProvider? _refreshProvider;
  bool _listenerAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerAdded) {
      _refreshProvider = context.read<ListingsRefreshProvider>();
      _refreshProvider!.addListener(_fetch);
      _listenerAdded = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _refreshProvider?.removeListener(_fetch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _api.getListings(
        search: _searchQuery?.isEmpty == true ? null : _searchQuery,
        category: _categoryFilter,
        isFree: _freeOnly,
      );
      if (mounted) {
        setState(() {
          _listings = result.listings;
          _total = result.total;
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
          _error = 'Could not load listings';
          _isLoading = false;
        });
      }
    }
  }

  void _applySearch() {
    setState(() => _searchQuery = _searchController.text.trim().isEmpty ? null : _searchController.text.trim());
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        backgroundColor: const Color(0xFF0F172A).withOpacity(0.85),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassContainer(
                  padding: EdgeInsets.zero,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search listings...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _applySearch(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isLoading)
                      Text(
                        _total == 1 ? '1 listing' : '$_total listings',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    const Spacer(),
                    _GridColumnsSelector(),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _categoryFilter == null && _freeOnly == null,
                        onTap: () {
                          setState(() {
                            _categoryFilter = null;
                            _freeOnly = null;
                          });
                          _fetch();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Free', selected: _freeOnly == true, onTap: () {
                        setState(() {
                          _freeOnly = true;
                          _categoryFilter = null;
                        });
                        _fetch();
                      }),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Furniture', selected: _categoryFilter == 'furniture', onTap: () {
                        setState(() {
                          _categoryFilter = 'furniture';
                          _freeOnly = null;
                        });
                        _fetch();
                      }),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Electronics', selected: _categoryFilter == 'electronics', onTap: () {
                        setState(() {
                          _categoryFilter = 'electronics';
                          _freeOnly = null;
                        });
                        _fetch();
                      }),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Books', selected: _categoryFilter == 'books', onTap: () {
                        setState(() {
                          _categoryFilter = 'books';
                          _freeOnly = null;
                        });
                        _fetch();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetch,
              color: const Color(0xFF38BDF8),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _listings.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }
    if (_error != null && _listings.isEmpty) {
      return _ErrorState(message: _error!, onRetry: _fetch);
    }
    if (_listings.isEmpty) {
      return _EmptyState();
    }

    return Consumer<GridColumnsProvider>(
      builder: (context, grid, _) {
        final cols = grid.columns;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: cols == 1 ? 2.8 : (cols == 2 ? 0.75 : 0.7),
          ),
          itemCount: _listings.length,
          itemBuilder: (context, i) {
            final listing = _listings[i];
            return _ListingGridTile(
              listing: listing,
              columns: cols,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ListingDetailScreen(listingId: listing.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GridColumnsSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GridColumnsProvider>(
      builder: (context, grid, _) {
        return IconButton(
          tooltip: 'Layout: ${grid.columns} column${grid.columns > 1 ? 's' : ''}',
          icon: Icon(
            grid.columns == 1 ? Icons.view_list : (grid.columns == 2 ? Icons.view_module : Icons.grid_view),
            color: Colors.white70,
            size: 22,
          ),
          onPressed: () => grid.cycleColumns(),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF38BDF8).withOpacity(0.25) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? const Color(0xFF38BDF8) : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingGridTile extends StatelessWidget {
  final Listing listing;
  final int columns;
  final VoidCallback onTap;

  const _ListingGridTile({required this.listing, required this.columns, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                    ? Image.network(
                        listing.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (listing.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'FREE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        )
                      else
                        Text(
                          '\$${listing.price?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      if (listing.category != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          listing.category!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.white.withOpacity(0.4)),
            const SizedBox(height: 24),
            Text(
              'No listings yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to post something!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
