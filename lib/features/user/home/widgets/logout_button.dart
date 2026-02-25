import 'package:flutter/material.dart';

/// Drawer çıkış yap butonu widget'ı
class HomeScreenLogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const HomeScreenLogoutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(
          height: 16,
          thickness: 0.5,
          indent: 20,
          endIndent: 20,
          color: Colors.grey,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Material(
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              hoverColor: Theme.of(
                context,
              ).colorScheme.error.withValues(alpha: 0.1),
              splashColor: Theme.of(
                context,
              ).colorScheme.error.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_outlined,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Çıkış Yap',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8.0),
      ],
    );
  }
}
