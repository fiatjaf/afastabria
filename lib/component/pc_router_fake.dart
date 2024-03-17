import "package:flutter/material.dart";

import "package:loure/provider/pc_router_fake_provider.dart";

class PcRouterFake extends InheritedWidget {
  const PcRouterFake({
    required super.child,
    required this.info,
    super.key,
  });
  final RouterFakeInfo info;

  static PcRouterFake? of(final BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PcRouterFake>();
  }

  @override
  bool updateShouldNotify(covariant final PcRouterFake oldWidget) {
    return false;
  }
}
