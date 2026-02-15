class ConversationListing {
  final String id;
  final String title;
  final String? imageUrl;
  final String? status;

  ConversationListing({
    required this.id,
    required this.title,
    this.imageUrl,
    this.status,
  });

  factory ConversationListing.fromJson(Map<String, dynamic> json) {
    return ConversationListing(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] as String?,
    );
  }
}

class ConversationUser {
  final String id;
  final String? name;
  final String email;
  final String? firebaseUid;

  ConversationUser({
    required this.id,
    this.name,
    required this.email,
    this.firebaseUid,
  });

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String,
      firebaseUid: json['firebaseUid'] as String?,
    );
  }
}

class ConversationMessage {
  final String id;
  final String content;
  final String senderId;
  final String? senderUid;
  final DateTime createdAt;
  final ConversationUser? sender;

  ConversationMessage({
    required this.id,
    required this.content,
    required this.senderId,
    this.senderUid,
    required this.createdAt,
    this.sender,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      senderId: json['senderId'] as String,
      senderUid: json['senderUid'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sender: json['sender'] != null
          ? ConversationUser.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  factory ConversationMessage.fromRtdb(String key, Map<dynamic, dynamic> data) {
    final createdAt = data['createdAt'];
    return ConversationMessage(
      id: key,
      content: data['content'] as String? ?? '',
      senderId: '',
      senderUid: data['senderUid'] as String?,
      createdAt: createdAt is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAt)
          : DateTime.now(),
      sender: null,
    );
  }
}

class Conversation {
  final String id;
  final String? listingId;
  final String initiatorId;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ConversationListing? listing;
  final ConversationUser initiator;
  final ConversationUser owner;
  final List<ConversationMessage> messages;

  Conversation({
    required this.id,
    this.listingId,
    required this.initiatorId,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.listing,
    required this.initiator,
    required this.owner,
    this.messages = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      listingId: json['listingId'] as String?,
      initiatorId: json['initiatorId'] as String,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      listing: json['listing'] != null
          ? ConversationListing.fromJson(json['listing'] as Map<String, dynamic>)
          : null,
      initiator: ConversationUser.fromJson(json['initiator'] as Map<String, dynamic>),
      owner: ConversationUser.fromJson(json['owner'] as Map<String, dynamic>),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => ConversationMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String otherUserName(String myId) {
    if (initiatorId == myId) return owner.name ?? owner.email.split('@').first;
    return initiator.name ?? initiator.email.split('@').first;
  }

  String? get previewText {
    final m = messages.isNotEmpty ? messages.first : null;
    if (m == null) return null;
    final t = m.content;
    return t.length > 60 ? '${t.substring(0, 60)}...' : t;
  }
}
