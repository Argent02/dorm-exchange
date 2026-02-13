import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'models/listing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();

  List<Listing> _listings = [];
  int _totalListings = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _api.getListings();
      setState(() {
        _listings = result.listings;
        _totalListings = result.total;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not connect to server';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dorm Exchange'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchListings,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User info from backend
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? user?.email ?? 'student'}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Synced with backend as ${user?.email ?? 'unknown'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'User ID: ${user?.id ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Listings section
            Text(
              'Listings ($_totalListings total)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_error!,
                          style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _fetchListings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_listings.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No listings yet.\nBe the first to post something!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              ..._listings.map((listing) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(listing.title),
                      subtitle: Text(
                        listing.isFree
                            ? 'FREE'
                            : '\$${listing.price?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      trailing: listing.category != null
                          ? Chip(label: Text(listing.category!))
                          : null,
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
