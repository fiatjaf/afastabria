import 'package:flutter/material.dart';

import 'package:loure/component/placeholder/event_placeholder.dart';

// ignore: must_be_immutable
class EventListPlaceholder extends StatelessWidget {
  Function? onRefresh;

  EventListPlaceholder({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        return const EventPlaceholder();
      },
      itemCount: 10,
    );
  }
}
