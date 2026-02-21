import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../providers/conversations_refresh_provider.dart';
import '../providers/grid_columns_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_container.dart';
import 'chat_screen.dart';

/// Screen to pick a listing and start a conversation with the seller.
class SelectListingToMessageScreen extends StatefulWidget {
  const SelectListingToMessageScreen({super.key});

  @override
  State<SelectListingToMessageScreen> createState() => _SelectListingToMessageScreenState();
}

class _SelectListingToMessageScreenState extends State<SelectListingToMessageScreen> {
  final ApiService _api = ApiService();
  final _searchController = TextEditingController();

  List<Listing> _listings = [];
  bool _isLoading = true;
  String? _error;
  String? _searchQuery;
  String? _categoryFilter;
  bool? _freeOnly;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
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

  Future<void> _onListingTap(Listing listing) async {
    final myId = context.read<AuthProvider>().currentUser?.id;
    final creatorId = listing.creator?.id ?? listing.createdBy;
    if (myId == null || creatorId == myId) return;

    try {
      final conv = await _api.createConversation(
        listingId: listing.id,
        ownerId: creatorId,
      );
      if (mounted) {
        context.read<ConversationsRefreshProvider>().trigger();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversationId: conv.id),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start a conversation'),
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick a listing to message the seller',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search listings...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) {
                      setState(() {
                        _searchQuery = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
                      });
                      _fetch();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All', selected: _categoryFilter == null && _freeOnly == null, onTap: () {
                        setState(() {
                          _categoryFilter = null;
                          _freeOnly = null;
                        });
                        _fetch();
                      }),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_listings.isEmpty) {
      return Center(
        child: Text(
          'No listings to message',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      );
    }

    return Consumer<GridColumnsProvider>(
      builder: (context, grid, _) {
        final cols = grid.columns;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: cols == 1 ? 2.8 : (cols == 2 ? 0.75 : 0.7),
          ),
          itemCount: _listings.length,
          itemBuilder: (context, i) {
            final listing = _listings[i];
            final myId = context.read<AuthProvider>().currentUser?.id ?? '';
            final creatorId = listing.creator?.id ?? listing.createdBy;
            final canMessage = myId != creatorId;

            return GlassContainer(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: canMessage ? () => _onListingTap(listing) : null,
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
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
                              if (!canMessage)
                                Text(
                                  'Your listing',
                                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (canMessage)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.message, size: 14, color: Color(0xFF38BDF8)),
                              SizedBox(width: 4),
                              Text('Message', style: TextStyle(fontSize: 12, color: Color(0xFF38BDF8))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.06),
      child: Icon(Icons.image_not_supported, color: Colors.white.withValues(alpha: 0.3), size: 32),
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
            color: selected ? const Color(0xFF38BDF8).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.15),
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
