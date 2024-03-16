import "package:flutter/material.dart";

import "package:loure/consts/base.dart";

class EventLoadListComponent extends StatelessWidget {
  const EventLoadListComponent({super.key});

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;

    return Container(
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      color: cardColor,
      height: 60,
      child: const Center(child: Text("Note loading...")),
    );
  }
}
