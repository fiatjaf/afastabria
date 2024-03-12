import 'package:flutter/material.dart';

import '../../consts/base.dart';

class TapPlaceholder extends StatelessWidget {
  Color color;

  double width;

  TapPlaceholder({super.key, required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
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
