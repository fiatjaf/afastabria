import "package:flutter/material.dart";
import "package:loure/main.dart";
import "package:loure/router/routes.dart";
import "package:loure/util/platform_util.dart";

// TODO: must set "clear" to true when this request is from home, globals, search or dms, just to clean stack and push
// TODO: make router() just render the widget and call push() -- then after that we can begin switching out of named routes

class RouterUtil {
  static Future<dynamic> router<T>(
      final BuildContext context, final String pageName,
      [final dynamic argument, final bool clear = false]) async {
    if (!PlatformUtil.isTableMode()) {
      return Navigator.of(context).pushNamed<T>(pageName, arguments: argument);
    } else {
      final widget =
          renderWidget(RouteSettings(name: pageName, arguments: argument));
      return internalRouter.push(widget, arg: argument, clear: clear);
    }
  }

  static void push(final BuildContext context, final Widget widget,
      {bool clear = false}) {
    if (!PlatformUtil.isTableMode()) {
      Navigator.of(context).push(MaterialPageRoute(builder: (final context) {
        return widget;
      }));
    } else {
      internalRouter.push(widget, clear: clear);
    }
  }

  static dynamic routerArgs(final BuildContext context) {
    RouteSettings? setting = ModalRoute.of(context)?.settings;
    if (setting != null) {
      if (!PlatformUtil.isTableMode()) {
        return setting.arguments;
      } else {
        return internalRouter.lastArgument();
      }
    }
    return null;
  }

  static void back(final BuildContext context, [final dynamic returnObj]) {
    if (!PlatformUtil.isTableMode()) {
      final NavigatorState ns = Navigator.of(context);
      if (ns.canPop()) {
        ns.pop(returnObj);
      }
    } else {
      internalRouter.pop(returnObj);
    }
  }
}
