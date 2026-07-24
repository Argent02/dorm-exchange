import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/listing.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/conversations_refresh_provider.dart';
import '../services/api_service.dart';
class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final ApiService _api = ApiService();
  Listing? _listing;
  bool _isLoading = true;
  String? _error;
  bool _saveInProgress = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _openChat(BuildContext context) async {
    final listing = _listing!;
    final creatorId = listing.creator?.id ?? listing.createdBy;
    final myId = context.read<AuthProvider>().currentUser?.id;
    if (myId == null) return;
    if (creatorId == myId) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This is your listing — you can\'t message yourself.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final conv = await _api.createConversation(
        listingId: listing.id,
        ownerId: creatorId,
      );
      if (context.mounted) {
        context.read<ConversationsRefreshProvider>().trigger();
        context.push('/chat/${conv.id}');
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _toggleSaved() async {
    if (_listing == null || _saveInProgress) return;
    setState(() => _saveInProgress = true);
    try {
      if (_listing!.isSaved) {
        await _api.unsaveListing(_listing!.id);
        if (mounted) {
          setState(() {
          _listing = _listing!.copyWith(isSaved: false);
          _saveInProgress = false;
        });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from saved'), behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        await _api.saveListing(_listing!.id);
        if (mounted) {
          setState(() {
          _listing = _listing!.copyWith(isSaved: true);
          _saveInProgress = false;
        });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to your list'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saveInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saveInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update saved status'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _fetch() async {
    try {
      final listing = await _api.getListing(widget.listingId);
      if (mounted) {
        setState(() {
        _listing = listing;
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
        _error = 'Could not load listing';
        _isLoading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_listing != null)
            IconButton(
              icon: Icon(
                _listing!.isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: _listing!.isSaved ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: _saveInProgress ? null : _toggleSaved,
              tooltip: _listing!.isSaved ? 'Remove from saved' : 'Save listing',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetch,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _listing == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_listing!.imageUrl != null && _listing!.imageUrl!.isNotEmpty)
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                _listing!.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.image_not_supported, size: 64, color: Theme.of(context).colorScheme.placeholderIcon),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 200,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.image_not_supported, size: 64, color: Theme.of(context).colorScheme.placeholderIcon),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_listing!.isFree)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'FREE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    '\$${_listing!.price?.toStringAsFixed(2) ?? '0.00'}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  _listing!.title,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                if (_listing!.category != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _listing!.category!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceMuted,
                                  ),
                                  ),
                                ],
                                if (_listing!.description != null && _listing!.description!.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    _listing!.description!,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                if (_listing!.creator != null)
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                            child: Text(
                                              (_listing!.creator!.name ?? _listing!.creator!.email)
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _listing!.creator!.name ?? 'Seller',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  _listing!.creator!.email,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Theme.of(context).colorScheme.onSurfaceMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Builder(
                                            builder: (context) {
                                              final creatorId = _listing!.creator?.id ?? _listing!.createdBy;
                                              final myId = context.watch<AuthProvider>().currentUser?.id;
                                              final isOwnListing = myId != null && creatorId == myId;
                                              return OutlinedButton.icon(
                                                onPressed: () => _openChat(context),
                                                icon: Icon(Icons.message, size: 18, color: isOwnListing ? Colors.white54 : null),
                                                label: Text(
                                                  isOwnListing ? 'Your listing' : 'Message',
                                                  style: TextStyle(color: isOwnListing ? Colors.white54 : null),
                                                ),
                                                style: isOwnListing
                                                    ? OutlinedButton.styleFrom(foregroundColor: Colors.white54)
                                                    : null,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
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
}
