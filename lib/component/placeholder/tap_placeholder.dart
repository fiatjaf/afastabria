import "package:flutter/material.dart";

import "package:loure/consts/base.dart";

class TapPlaceholder extends StatelessWidget {
  TapPlaceholder({required this.width, required this.color, super.key});
  Color color;

  double width;

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: width,
      height: 30,
      padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
