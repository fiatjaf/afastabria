import 'package:flutter/material.dart';

import 'package:nostrmo/component/placeholder/event_placeholder.dart';

class EventListPlaceholder extends StatelessWidget {
  Function? onRefresh;

  EventListPlaceholder({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) {
          onRefresh!();
        }
      },
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return const EventPlaceholder();
        },
        itemCount: 10,
      ),
    );
  }
}
