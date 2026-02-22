class AppUser {
  final String id;
  final String firebaseUid;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? phone;
  final String role;
  final bool isVerified;
  final int reportCount;
  final DateTime joinDate;

  AppUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.name,
    this.avatarUrl,
    this.phone,
    this.dorm,
    required this.role,
    required this.isVerified,
    required this.reportCount,
    required this.joinDate,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      dorm: json['dorm'] as String?,
      role: json['role'] as String,
      isVerified: json['isVerified'] as bool,
      reportCount: json['reportCount'] as int,
      joinDate: DateTime.parse(json['joinDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'dorm': dorm,
      'role': role,
      'isVerified': isVerified,
      'reportCount': reportCount,
      'joinDate': joinDate.toIso8601String(),
    };
  }
}
