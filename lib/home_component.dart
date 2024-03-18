import "package:flutter/material.dart";
import "package:loure/component/webview_router.dart";
import "package:loure/main.dart";
import "package:loure/provider/webview_provider.dart";
import "package:loure/util/platform_util.dart";
import "package:provider/provider.dart";

class HomeComponent extends StatefulWidget {
  const HomeComponent({
    required this.child,
    super.key,
    this.theme,
  });
  final Widget child;
  final ThemeData? theme;

  @override
  State<StatefulWidget> createState() {
    return HomeComponentState();
  }
}

class HomeComponentState extends State<HomeComponent> {
  @override
  Widget build(final BuildContext context) {
    PlatformUtil.init(context);
    final webviewProvider = Provider.of<WebViewProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: widget.theme,
      home: Stack(
        children: [
          Positioned.fill(child: widget.child),
          webViewProvider.url != null
              ? Positioned(
                  child: Offstage(
                  offstage: !webviewProvider.showable,
                  child: WebViewRouter(url: webviewProvider.url!),
                ))
              : Container()
        ],
      ),
    );
  }
}
