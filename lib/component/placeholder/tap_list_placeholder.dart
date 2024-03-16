import "dart:math";

import "package:flutter/material.dart";
import "package:loure/component/placeholder/tap_placeholder.dart";

class TapListPlaceholder extends StatelessWidget {
  const TapListPlaceholder({super.key});

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;

    final random = Random();
    const double width = 40;

    List<Widget> list = [];
    for (var i = 0; i < 60; i++) {
      final rndWidth = random.nextDouble() * width + 20;
      list.add(TapPlaceholder(width: rndWidth, color: hintColor));
    }

    return Container(
      child: Center(
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: list,
        ),
      ),
    );
  }
}
