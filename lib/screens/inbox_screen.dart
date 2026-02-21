import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../providers/auth_provider.dart';
import '../providers/conversations_refresh_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_container.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ApiService _api = ApiService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _error;
  ConversationsRefreshProvider? _refreshProvider;
  bool _listenerAdded = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerAdded) {
      _refreshProvider = context.read<ConversationsRefreshProvider>();
      _refreshProvider!.addListener(_fetch);
      _listenerAdded = true;
    }
  }

  @override
  void dispose() {
    _refreshProvider?.removeListener(_fetch);
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _api.getConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
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
          _error = 'Could not load conversations';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            tooltip: 'New message',
            onPressed: () => context.push('/select-listing').then((_) => _fetch()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: const Color(0xFF38BDF8),
        child: _buildBody(userId),
      ),
    );
  }

  Widget _buildBody(String userId) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(height: 24),
              Text(
                'No messages yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button above to start a conversation with a seller.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/select-listing').then((_) => _fetch()),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_comment, color: Theme.of(context).colorScheme.primary, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, i) {
        final c = _conversations[i];
        return _ConversationTile(
          conversation: c,
          myId: userId,
          onTap: () => context.push('/chat/${c.id}').then((_) => _fetch()),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String myId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.myId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = conversation.otherUserName(myId);
    final preview = conversation.previewText;
    final listing = conversation.listing;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            if (listing?.imageUrl != null && listing!.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  listing.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
              )
            else
              _placeholder(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  if (listing != null)
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (preview != null)
                    Text(
                      preview,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.chat_bubble_outline, color: Colors.white.withValues(alpha: 0.4)),
    );
  }
}
