class ActivityLog {
  final int id;
  final int adminId;
  final String adminUsername;
  final String actionType;
  final int? targetUserId;
  final String? targetUsername;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.adminId,
    required this.adminUsername,
    required this.actionType,
    this.targetUserId,
    this.targetUsername,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      adminId: json['admin_id'],
      adminUsername: json['admin_username'] ?? '',
      actionType: json['action_type'],
      targetUserId: json['target_user_id'],
      targetUsername: json['target_username'],
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'])
          : null,
      ipAddress: json['ip_address'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'admin_username': adminUsername,
      'action_type': actionType,
      'target_user_id': targetUserId,
      'target_username': targetUsername,
      'details': details,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get actionDescription {
    switch (actionType) {
      case 'user_created':
        return 'Kullanıcı oluşturuldu';
      case 'user_updated':
        return 'Kullanıcı güncellendi';
      case 'user_deleted':
        return 'Kullanıcı silindi';
      case 'user_blocked':
        return 'Kullanıcı bloklandı';
      case 'user_unblocked':
        return 'Kullanıcı aktif edildi';
      case 'admin_granted':
        return 'Admin yetkisi verildi';
      case 'admin_revoked':
        return 'Admin yetkisi kaldırıldı';
      case 'password_changed':
        return 'Şifre değiştirildi';
      case 'profile_updated':
        return 'Profil güncellendi';
      case 'login':
        return 'Giriş yapıldı';
      case 'logout':
        return 'Çıkış yapıldı';
      case 'failed_login':
        return 'Başarısız giriş denemesi';
      default:
        return actionType;
    }
  }

  String get targetInfo {
    if (targetUsername != null) {
      return '@$targetUsername';
    } else if (targetUserId != null) {
      return 'ID: $targetUserId';
    }
    return '-';
  }
}
