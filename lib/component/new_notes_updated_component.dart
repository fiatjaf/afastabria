import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base.dart';

// ignore: must_be_immutable
class NewNotesUpdatedComponent extends StatelessWidget {
  int num;

  Function? onTap;

  NewNotesUpdatedComponent({super.key, required this.num, this.onTap});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    Color? textColor = Colors.white;

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
