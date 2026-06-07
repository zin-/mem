import 'package:flutter/material.dart';

void syncTextEditingController({
  required TextEditingController controller,
  required bool mounted,
  required String Function() buildText,
  bool postFrame = false,
}) {
  if (!mounted) return;

  void apply() {
    if (!mounted) return;
    final text = buildText();
    if (controller.text != text) {
      controller.text = text;
    }
  }

  if (postFrame) {
    WidgetsBinding.instance.addPostFrameCallback((_) => apply());
  } else {
    apply();
  }
}
