import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Klavye açıldığında form field'larını görünür hale getiren yardımcı sınıf
class ScrollHelper {
  final ScrollController scrollController;
  Timer? _ensureTimer;
  bool _isEnsuring = false;

  ScrollHelper(this.scrollController);

  void dispose() {
    _ensureTimer?.cancel();
  }

  void scheduleEnsureVisible(GlobalKey key) {
    _ensureTimer?.cancel();
    _ensureTimer = Timer(const Duration(milliseconds: 90), () {
      ensureVisible(key);
    });
  }

  Future<void> ensureVisible(GlobalKey key) async {
    if (!scrollController.hasClients) return;
    if (_isEnsuring) return;

    _isEnsuring = true;
    try {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!scrollController.hasClients) return;

      final ctx = key.currentContext;
      if (ctx == null) return;

      final renderObject = ctx.findRenderObject();
      if (renderObject == null) return;

      final viewport = RenderAbstractViewport.of(renderObject);
      final alignment = 0.18;
      final extra = 24.0;

      final reveal = viewport.getOffsetToReveal(renderObject, alignment);

      final target = (reveal.offset - extra).clamp(
        scrollController.position.minScrollExtent,
        scrollController.position.maxScrollExtent,
      );

      final current = scrollController.offset;
      if ((target - current).abs() > 2) {
        scrollController.jumpTo(target);
      }
    } finally {
      _isEnsuring = false;
    }
  }

  void bindFocusNode(FocusNode node, GlobalKey key) {
    node.addListener(() {
      if (node.hasFocus) scheduleEnsureVisible(key);
    });
  }
}
