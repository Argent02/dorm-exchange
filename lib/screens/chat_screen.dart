import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/api_service.dart';
import '../services/rtdb_service.dart';
import '../widgets/glass_container.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  Conversation? _conversation;
  List<ConversationMessage> _messages = [];
  bool _isLoading = true;
  String? _error;
  bool _isSending = false;
  DateTime? _newestMessageTime;
  StreamSubscription<dynamic>? _rtdbSubscription;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rtdbSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conv = await _api.getConversation(widget.conversationId);
      final msgs = await _api.getMessages(widget.conversationId);
      if (mounted) {
        DateTime? newest;
        for (final m in msgs) {
          if (newest == null || m.createdAt.isAfter(newest)) newest = m.createdAt;
        }
        setState(() {
          _conversation = conv;
          _messages = msgs;
          _newestMessageTime = newest;
          _isLoading = false;
        });
        _scrollToBottom();
        _setupRtdb(conv);
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
          _error = 'Could not load messages';
          _isLoading = false;
        });
      }
    }
  }

  void _setupRtdb(Conversation conv) {
    final initiatorUid = conv.initiator.firebaseUid;
    final ownerUid = conv.owner.firebaseUid;
    if (initiatorUid == null || ownerUid == null) return;

    RtdbService.ensureConversation(widget.conversationId, initiatorUid, ownerUid).then((_) {
      if (!mounted) return;
      _rtdbSubscription = RtdbService.watchMessages(widget.conversationId).listen((event) {
        // RTDB event acts as a realtime signal; backend remains the source of truth.
        _refreshMessages();
      });
    });
  }

  Future<void> _refreshMessages() async {
    try {
      final msgs = await _api.getMessages(widget.conversationId);
      if (!mounted) return;

      DateTime? newest;
      for (final m in msgs) {
        if (newest == null || m.createdAt.isAfter(newest)) newest = m.createdAt;
      }

      setState(() {
        _messages = msgs;
        _newestMessageTime = newest;
      });
      _scrollToBottom();
    } catch (_) {
      // Keep current UI state if refresh fails; a later signal/manual retry can recover.
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      final persisted = await _api.sendMessage(widget.conversationId, text);

      if (mounted) {
        setState(() {
          _messages = [..._messages, persisted];
          if (_newestMessageTime == null || persisted.createdAt.isAfter(_newestMessageTime!)) {
            _newestMessageTime = persisted.createdAt;
          }
          _isSending = false;
        });
        _scrollToBottom();
      }

      // Best-effort realtime signal after backend persistence succeeds.
      await RtdbService.signalMessage(widget.conversationId);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  bool _isMe(ConversationMessage m) {
    final myBackendId = context.read<app_auth.AuthProvider>().currentUser?.id ?? '';
    final myFirebaseUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (m.senderUid != null) return m.senderUid == myFirebaseUid;
    return m.senderId == myBackendId;
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<app_auth.AuthProvider>().currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_conversation?.otherUserName(userId) ?? 'Chat'),
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          return _MessageBubble(message: m, isMe: _isMe(m));
                        },
                      ),
                    ),
                    _buildInput(),
                  ],
                ),
    );
  }

  Widget _buildInput() {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSending ? null : _send,
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                  )
                : const Icon(Icons.send),
            color: const Color(0xFF38BDF8),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ConversationMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
