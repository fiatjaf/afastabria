import "package:flutter/material.dart";

import "package:loure/component/placeholder/event_placeholder.dart";

// ignore: must_be_immutable
class EventListPlaceholder extends StatelessWidget {
  EventListPlaceholder({super.key, this.onRefresh});
  Function? onRefresh;

  @override
  Widget build(final BuildContext context) {
    return ListView.builder(
      itemBuilder: (final BuildContext context, final int index) {
        return const EventPlaceholder();
      },
      itemCount: 10,
    );
  }
}
