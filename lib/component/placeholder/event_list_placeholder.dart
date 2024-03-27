import "package:flutter/material.dart";

import "package:loure/component/placeholder/event_placeholder.dart";

class EventListPlaceholder extends StatelessWidget {
  const EventListPlaceholder({super.key, this.onRefresh});
  final Function? onRefresh;

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
