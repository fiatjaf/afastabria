import "dart:async";

import "package:flutter/material.dart";

abstract class KeepAliveCustState<T extends StatefulWidget> extends State<T>
    with AutomaticKeepAliveClientMixin {
  bool isInited = false;

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    final Widget w = doBuild(context);

    if (!isInited) {
      isInited = true;
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        this.onReady(context);
      });
    }

    return w;
  }

  Widget doBuild(final BuildContext context);

  Future<void> onReady(final BuildContext context);

  // @override
  // void dispose() {
  //   super.dispose();
  // }

  // @override
  // void initState() {
  //   super.initState();
  // }

  @override
  bool get wantKeepAlive => true;
}
