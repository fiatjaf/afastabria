import "package:flutter/material.dart";

class PointComponent extends StatelessWidget {
  PointComponent({
    super.key,
    this.marginRight = 0,
    this.marginTop = 0,
    this.width = 10,
    this.color,
  });
  double marginTop;

  double marginRight;

  double width;

  Color? color;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    var textColor = themeData.textTheme.bodyMedium!.color;
    if (color != null) {
      textColor = color;
    }

    return Container(
      width: width,
      height: width,
      margin: EdgeInsets.only(
        top: marginTop,
        right: marginRight,
      ),
      decoration: BoxDecoration(
        color: textColor!,
        borderRadius: BorderRadius.all(
          Radius.circular(width / 2),
        ),
      ),
    );
  }
}
