import "dart:async";

import "package:flutter/material.dart";
import "package:loure/component/pc_router_fake.dart";
import "package:loure/main.dart";
import "package:loure/util/platform_util.dart";

import "package:loure/provider/pc_router_fake_provider.dart";

class RouterUtil {
  static Future<T?> router<T>(final BuildContext context, final String pageName,
      [final Object? arguments]) async {
    if (!PlatformUtil.isTableMode()) {
      return Navigator.of(context).pushNamed<T>(pageName, arguments: arguments);
    } else {
      bool clear = false;
      final parentRouterFake = PcRouterFake.of(context);
      if (parentRouterFake == null) {
        // means this request is from home, globals, search or dms, just to clean stack and push
        clear = true;
      }
      final routerFakeInfo =
          RouterFakeInfo<T>(routerPath: pageName, arguments: arguments);
      pcRouterFakeProvider.router<T>(routerFakeInfo, clear: clear);

      return routerFakeInfo.completer.future;
    }
  }

  static Future<T?> push<T extends Object?>(
      final BuildContext context, final MaterialPageRoute<T> route) {
    if (!PlatformUtil.isTableMode()) {
      return Navigator.of(context).push(route);
    } else {
      bool clear = false;
      final parentRouterFake = PcRouterFake.of(context);
      if (parentRouterFake == null) {
        // means this request is from home, globals, search or dms, just to clean stack and push
        clear = true;
      }
      final routerFakeInfo =
          RouterFakeInfo<T>(buildContent: route.buildContent);
      pcRouterFakeProvider.router<T>(routerFakeInfo, clear: clear);

      return routerFakeInfo.completer.future;
    }
  }

  static Object? routerArgs(final BuildContext context) {
    RouteSettings? setting = ModalRoute.of(context)?.settings;
    if (setting != null) {
      if (!PlatformUtil.isTableMode()) {
        return setting.arguments;
      } else {
        final fake = PcRouterFake.of(context);
        if (fake != null) {
          return fake.info.arguments;
        }
      }
    }
    return null;
  }

  static void back(final BuildContext context, [final Object? returnObj]) {
    final NavigatorState ns = Navigator.of(context);

    final parentRouterFake = PcRouterFake.of(context);
    if (parentRouterFake == null) {
      if (ns.canPop()) {
        ns.pop(returnObj);
      }
    } else {
      // handle pop result
      final info = parentRouterFake.info;
      pcRouterFakeProvider.remove(info);
      info.completer.complete(returnObj);
    }
  }
}
