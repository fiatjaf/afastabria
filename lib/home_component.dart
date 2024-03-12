import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/webview_provider.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:provider/provider.dart';

class HomeComponent extends StatefulWidget {
  Widget child;

  Locale? locale;

  ThemeData? theme;

  HomeComponent({super.key, 
    required this.child,
    this.locale,
    this.theme,
  });

  @override
  State<StatefulWidget> createState() {
    return _HomeComponent();
  }
}

class _HomeComponent extends State<HomeComponent> {
  @override
  Widget build(BuildContext context) {
    PlatformUtil.init(context);
    var webviewProvider = Provider.of<WebViewProvider>(context);

    return MaterialApp(
      locale: widget.locale,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
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
