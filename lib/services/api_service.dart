import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/conversation.dart';
import '../models/exchange.dart';
import '../models/listing.dart';
import '../models/notification.dart';
import '../models/user.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ─── Base URL Configuration ──────────────────────────────
  // In release/production builds, point to your deployed server URL.
  // In debug builds, pick the right address per platform:
  //   - Physical device: use your host machine's local IP (same Wi-Fi network)
  //   - Android emulator: 10.0.2.2 maps to host's localhost
  //   - iOS simulator / macOS / web: localhost works directly
  //
  // Set your host machine's current IP here for physical device testing.
  // The dev.sh script updates this automatically on each run.
  //
  // Release builds MUST provide API_BASE_URL via --dart-define.
  // Example:
  // flutter build ipa --release --dart-define=API_BASE_URL=https://api.example.com
  static const String _localIp = '10.0.0.204';
  static const String _releaseApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static void _validateReleaseApiBaseUrl() {
    if (_releaseApiBaseUrl.isEmpty) {
      throw StateError(
        'Missing API_BASE_URL for release build. Provide --dart-define=API_BASE_URL=https://your-api-host.',
      );
    }

    final uri = Uri.tryParse(_releaseApiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError(
        'Invalid API_BASE_URL for release build: "$_releaseApiBaseUrl". Expected an absolute URL.',
      );
    }

    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      throw StateError(
        'API_BASE_URL cannot point to localhost in release builds.',
      );
    }
  }

  static String get _baseUrl {
    if (kReleaseMode) {
      _validateReleaseApiBaseUrl();
      return _releaseApiBaseUrl;
    }
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    if (Platform.isIOS) return 'http://$_localIp:3000';
    // macOS, Windows, Linux — localhost works
    return 'http://localhost:3000';
  }

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

  /// Updates the current user's profile (name, avatarUrl, phone, dorm).
  Future<AppUser> updateMe({
    String? name,
    String? avatarUrl,
    String? phone,
    String? dorm,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (phone != null) body['phone'] = phone;
    if (dorm != null) body['dorm'] = dorm.isEmpty ? null : dorm;
    final data = await _patch('/auth/me', body: body.isNotEmpty ? body : null);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Gets the current user's profile with their listings.
  Future<({AppUser user, List<Listing> listings})> getMeWithListings() async {
    final data = await _get('/auth/me');
    final userJson = data['user'] as Map<String, dynamic>;
    final user = AppUser.fromJson(userJson);
    final listingsJson = userJson['listings'] as List<dynamic>? ?? [];
    final listings = listingsJson
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
    return (user: user, listings: listings);
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

  // ─── Conversation Endpoints ──────────────────────────────

  Future<List<Conversation>> getConversations() async {
    final data = await _get('/conversations');
    return (data['conversations'] as List<dynamic>)
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> getConversation(String id) async {
    final data = await _get('/conversations/$id');
    return Conversation.fromJson(data['conversation'] as Map<String, dynamic>);
  }

  Future<Conversation> createConversation({String? listingId, required String ownerId}) async {
    final data = await _post('/conversations', body: {
      if (listingId != null) 'listingId': listingId,
      'ownerId': ownerId,
    });
    return Conversation.fromJson(data['conversation'] as Map<String, dynamic>);
  }

  Future<List<ConversationMessage>> getMessages(String conversationId) async {
    final data = await _get('/conversations/$conversationId/messages');
    return (data['messages'] as List<dynamic>)
        .map((e) => ConversationMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationMessage> sendMessage(String conversationId, String content) async {
    final data = await _post('/conversations/$conversationId/messages', body: {'content': content});
    return ConversationMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  // ─── Exchange Endpoints ──────────────────────────────────

  Future<({
    List<Exchange> bought,
    List<Exchange> sold,
    List<SoldListingDisplay> soldListings,
  })> getMyExchanges() async {
    final data = await _get('/exchanges');
    final bought = (data['bought'] as List<dynamic>)
        .map((e) => Exchange.fromJson(e as Map<String, dynamic>))
        .toList();
    final sold = (data['sold'] as List<dynamic>)
        .map((e) => Exchange.fromJson(e as Map<String, dynamic>))
        .toList();
    final soldListingsRaw = data['soldListings'] as List<dynamic>? ?? [];
    final soldListings = soldListingsRaw
        .map((e) => SoldListingDisplay.fromJson(e as Map<String, dynamic>))
        .toList();
    return (bought: bought, sold: sold, soldListings: soldListings);
  }

  // ─── Saved Endpoints ─────────────────────────────────────

  Future<List<Listing>> getSavedListings() async {
    final data = await _get('/saved');
    return (data['listings'] as List<dynamic>)
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveListing(String listingId) async {
    await _post('/saved/$listingId');
  }

  Future<void> unsaveListing(String listingId) async {
    await _delete('/saved/$listingId');
  }

  // ─── Notifications Endpoints ─────────────────────────────

  Future<List<AppNotification>> getNotifications() async {
    final data = await _get('/notifications');
    return (data['notifications'] as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _patch('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _post('/notifications/read-all');
  }

  Future<dynamic> _delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _authHeaders();
    final response = await http.delete(uri, headers: headers);
    return _handleResponse(response);
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
