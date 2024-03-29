import "package:flutter/material.dart";
import "package:loure/consts/base.dart";

// ignore: must_be_immutable
class NewNotesUpdatedComponent extends StatelessWidget {
  NewNotesUpdatedComponent({required this.num, super.key, this.onTap});

  int num;
  Function? onTap;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    Color? textColor = Colors.white;

    if (num <= 0) {
      return Container();
    }

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
          color: mainColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "$num notes updated",
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}
