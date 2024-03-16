import "package:flutter/material.dart";

import "package:loure/client/event.dart";

class EventDeleteCallback extends InheritedWidget {
  EventDeleteCallback({
    required super.child,
    required this.onDeleteCallback,
    super.key,
  });
  Function(Event) onDeleteCallback;

  static EventDeleteCallback? of(final BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EventDeleteCallback>();
  }

  @override
  bool updateShouldNotify(covariant final EventDeleteCallback oldWidget) {
    return false;
  }

  void onDelete(final Event event) {
    onDeleteCallback(event);
  }
}
