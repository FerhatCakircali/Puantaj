import 'package:flutter/material.dart';

/// Kullanıcı listesi boş durum widget'ı
class UsersEmptyState extends StatelessWidget {
  final bool hasSearchQuery;

  const UsersEmptyState({super.key, required this.hasSearchQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchQuery
                ? 'Arama kriterlerine uygun kullanıcı bulunamadı'
                : 'Henüz kullanıcı bulunmuyor',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
