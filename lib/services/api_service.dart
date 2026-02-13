import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/listing.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Base URL — localhost for dev, change to Railway URL for production.
  // Android emulator uses 10.0.2.2 to reach host machine's localhost.
  // iOS simulator and web use localhost directly.
  static const String _baseUrl = 'http://localhost:3000';

  // ─── Auth Header ─────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── Generic Request Helpers ─────────────────────────────

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: queryParams);
    final headers = await _authHeaders();
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _authHeaders();
    final response = await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _put(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _authHeaders();
    final response = await http.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _patch(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _authHeaders();
    final response = await http.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = body['error'] as String? ?? 'Request failed';
    throw ApiException(response.statusCode, error);
  }

  // ─── Auth Endpoints ──────────────────────────────────────

  /// Syncs the current Firebase user to the backend database.
  /// Call this after Firebase sign-in/sign-up.
  Future<AppUser> login() async {
    final data = await _post('/auth/login');
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Gets the current user's full profile from the backend.
  Future<AppUser> getMe() async {
    final data = await _get('/auth/me');
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ─── Listings Endpoints ──────────────────────────────────

  /// Fetches paginated listings with optional filters.
  Future<PaginatedListings> getListings({
    String? search,
    String? category,
    bool? isFree,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (isFree != null) queryParams['isFree'] = isFree.toString();

    final data = await _get('/listings', queryParams: queryParams);
    return PaginatedListings.fromJson(data);
  }

  /// Fetches a single listing by ID.
  Future<Listing> getListing(String id) async {
    final data = await _get('/listings/$id');
    return Listing.fromJson(data['listing'] as Map<String, dynamic>);
  }

  /// Creates a new listing.
  Future<Listing> createListing({
    required String title,
    String? description,
    String? imageUrl,
    double? price,
    bool isFree = false,
    String? category,
  }) async {
    final data = await _post('/listings', body: {
      'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (price != null) 'price': price,
      'isFree': isFree,
      if (category != null) 'category': category,
    });
    return Listing.fromJson(data['listing'] as Map<String, dynamic>);
  }

  /// Updates an existing listing.
  Future<Listing> updateListing(String id, Map<String, dynamic> updates) async {
    final data = await _put('/listings/$id', body: updates);
    return Listing.fromJson(data['listing'] as Map<String, dynamic>);
  }

  /// Updates a listing's status (active, sold, taken, deleted).
  Future<Listing> updateListingStatus(String id, String status) async {
    final data = await _patch('/listings/$id/status', body: {
      'status': status,
    });
    return Listing.fromJson(data['listing'] as Map<String, dynamic>);
  }

  // ─── User Endpoints ──────────────────────────────────────

  /// Gets a public user profile by ID.
  Future<Map<String, dynamic>> getUser(String id) async {
    final data = await _get('/users/$id');
    return data['user'] as Map<String, dynamic>;
  }
}

// ─── Custom Exception ────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
