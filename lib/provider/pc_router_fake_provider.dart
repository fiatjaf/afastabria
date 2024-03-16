import "dart:async";

import "package:flutter/material.dart";

class PcRouterFakeProvider extends ChangeNotifier {
  static int MAX_STACK_NUM = 20;

  List<RouterFakeInfo> routerFakeInfos = [];

  void router<T>(
    final RouterFakeInfo routerFakeInfo, {
    final bool clear = false,
  }) {
    List<RouterFakeInfo> newList = [];
    final oldLength = routerFakeInfos.length;

    if (!clear) {
      if (oldLength < MAX_STACK_NUM - 1) {
        newList.addAll(routerFakeInfos);
      } else {
        for (var i = 1; i < oldLength; i++) {
          newList.add(routerFakeInfos[i]);
        }
      }
    }

    newList.add(routerFakeInfo);

    routerFakeInfos = newList;
    notifyListeners();
  }

  void remove(final RouterFakeInfo info) {
    List<RouterFakeInfo> newList = [];
    routerFakeInfos.remove(info);
    newList.addAll(routerFakeInfos);
    routerFakeInfos = newList;
    notifyListeners();
  }
}

class RouterFakeInfo<T> {
  RouterFakeInfo({
    this.routerPath,
    this.arguments,
    this.buildContent,
  });
  String? routerPath;

  Object? arguments;

  final Completer<T> completer = Completer<T>();

  Widget Function(BuildContext)? buildContent;
}
