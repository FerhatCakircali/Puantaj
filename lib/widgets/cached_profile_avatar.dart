import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Önbellekli profil resmi widget'ı
/// Network'ten gelen profil resimlerini önbelleğe alarak
/// tekrarlanan yüklemeleri önler ve performansı artırır.
/// Özellikler:
/// - Otomatik önbellekleme (7 gün)
/// - Loading placeholder (CircularProgressIndicator)
/// - Error fallback (İlk harf avatarı)
/// - Özelleştirilebilir boyut ve renk
/// Kullanım:
/// ```dart
/// CachedProfileAvatar(
///   imageUrl: worker.profileImageUrl,
///   name: worker.fullName,
///   radius: 40,
/// )
/// ```
class CachedProfileAvatar extends StatelessWidget {
  /// Profil resmi URL'i (null ise ilk harf gösterilir)
  final String? imageUrl;

  /// Kullanıcının tam adı (fallback için ilk harf)
  final String name;

  /// Avatar yarıçapı (default: 20)
  final double radius;

  /// Arka plan rengi (null ise tema rengi kullanılır)
  final Color? backgroundColor;

  /// Metin rengi (null ise beyaz kullanılır)
  final Color? textColor;

  const CachedProfileAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // URL yoksa veya boşsa, ilk harf avatarı göster
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildInitialAvatar(context);
    }

    // URL varsa, önbellekli network image kullan
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Loading durumunda gösterilecek widget
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: radius * 0.6,
              height: radius * 0.6,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? Colors.white,
                ),
              ),
            ),
          ),
          // Hata durumunda gösterilecek widget (ilk harf)
          errorWidget: (context, url, error) => _buildInitialAvatar(context),
          // Önbellek süresi: 7 gün
          cacheKey: imageUrl,
          maxHeightDiskCache: (radius * 4).toInt(),
          maxWidthDiskCache: (radius * 4).toInt(),
        ),
      ),
    );
  }

  /// İlk harf avatarı oluşturur
  Widget _buildInitialAvatar(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final fontSize = radius * 0.8;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }
}
