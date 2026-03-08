import 'package:flutter/material.dart';

/// Kullanıcı arama çubuğu
class UsersSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const UsersSearchBar({
    super.key,
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Kullanıcı Ara',
        hintText: 'Ad, soyad, kullanıcı adı veya meslek...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
