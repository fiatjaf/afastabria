import "package:flutter/material.dart";

import "package:loure/client/event.dart";

// ignore: must_be_immutable
class EventReplyCallback extends InheritedWidget {
  EventReplyCallback({
    required super.child,
    required this.onReplyCallback,
    super.key,
  });
  Function(Event) onReplyCallback;

  static EventReplyCallback? of(final BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EventReplyCallback>();
  }

  @override
  bool updateShouldNotify(covariant final EventReplyCallback oldWidget) {
    return false;
  }

  void onReply(final Event event) {
    onReplyCallback(event);
  }
}
