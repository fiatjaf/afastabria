import "dart:convert";
import "package:flutter/material.dart";
import "package:loure/client/client_utils/keys.dart";
import "package:loure/main.dart";
import "package:http/http.dart" as http;

import "package:loure/component/name_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/router/routes.dart";
import "package:loure/data/metadata.dart";
import "package:loure/component/image_component.dart";
import "package:loure/component/webview_router.dart";
import "package:loure/util/router_util.dart";
import "package:loure/client/relay/relay_info.dart";

class RelayInfoRouter extends StatefulWidget {
  const RelayInfoRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return RelayInfoRouterState();
  }
}

class RelayInfoRouterState extends State<RelayInfoRouter> {
  double IMAGE_WIDTH = 45;
  RelayInfo? info;
  String? url;

  Future<Metadata>? ownerFuture;

  @override
  void initState() {
    super.initState();

    final url = RouterUtil.routerArgs(context);
    if (url == null || url is! String) {
      RouterUtil.back(context);
      return;
    }

    http.get(Uri.parse(url).replace(scheme: "https"),
        headers: {"Accept": "application/nostr+json"}).then((final response) {
      this.setState(() {
        this.url = url;
        this.info = RelayInfo.fromJson(jsonDecode(response.body) as Map);
      });
    });

    this.ownerFuture = this.info != null && keyIsValid(this.info!.pubkey)
        ? metadataLoader.load(this.info!.pubkey)
        : null;
  }

  @override
  Widget build(final BuildContext context) {
    if (this.info == null) return Container();

    final themeData = Theme.of(context);
    final titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    // var mainColor = themeData.primaryColor;

    List<Widget> list = [];

    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      child: Text(
        this.info!.name,
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
      ),
      child: Text(this.info!.description),
    ));

    list.add(RelayInfoItemComponent(
      title: "URL",
      child: SelectableText(this.url!),
    ));

    if (this.ownerFuture != null) {
      list.add(
        RelayInfoItemComponent(
          title: "Owner",
          child: FutureBuilder(
            future: ownerFuture,
            initialData: Metadata.blank(this.info!.pubkey),
            builder: (final context, final snapshot) {
              final metadata = snapshot.data;

              Widget? imageWidget;
              if (metadata != null || metadata!.isBlank()) {
                imageWidget = ImageComponent(
                  imageUrl: metadata.picture!,
                  width: IMAGE_WIDTH,
                  height: IMAGE_WIDTH,
                  fit: BoxFit.cover,
                  placeholder: (final context, final url) =>
                      const CircularProgressIndicator(),
                );
              }

              List<Widget> list = [];
              list.add(Container(
                alignment: Alignment.center,
                height: IMAGE_WIDTH,
                width: IMAGE_WIDTH,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
                  color: Colors.grey,
                ),
                child: imageWidget,
              ));

              list.add(Container(
                margin: const EdgeInsets.only(left: Base.BASE_PADDING),
                child: NameComponent(
                  pubkey: this.info!.pubkey,
                  metadata: metadata,
                ),
              ));

              return GestureDetector(
                onTap: () {
                  RouterUtil.router(
                      context, RouterPath.USER, this.info!.pubkey);
                },
                child: Row(
                  children: list,
                ),
              );
            },
          ),
        ),
      );
    }

    list.add(RelayInfoItemComponent(
      title: "Contact",
      child: SelectableText(this.info!.contact),
    ));

    list.add(RelayInfoItemComponent(
      title: "Soft",
      child: SelectableText(this.info!.software),
    ));

    list.add(RelayInfoItemComponent(
      title: "Version",
      child: SelectableText(this.info!.version),
    ));

    List<Widget> nipWidgets = [];
    for (final nip in this.info!.nips) {
      nipWidgets.add(NipComponent(nip: nip));
    }
    list.add(RelayInfoItemComponent(
      title: "NIPs",
      child: Wrap(
        spacing: Base.BASE_PADDING,
        runSpacing: Base.BASE_PADDING,
        children: nipWidgets,
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        title: Text(
          "Relay Info",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: list,
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class RelayInfoItemComponent extends StatelessWidget {
  RelayInfoItemComponent({
    required this.title,
    required this.child,
    super.key,
  });
  String title;

  Widget child;

  @override
  Widget build(final BuildContext context) {
    List<Widget> list = [];

    list.add(
      Text(
        "$title :",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    list.add(Container(
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: child,
    ));

    return Container(
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
      ),
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}

// ignore: must_be_immutable
class NipComponent extends StatelessWidget {
  NipComponent({required this.nip, super.key});
  dynamic nip;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;

    var nipStr = nip.toString();
    if (nipStr == "1") {
      nipStr = "01";
    } else if (nipStr == "2") {
      nipStr = "02";
    } else if (nipStr == "3") {
      nipStr = "03";
    } else if (nipStr == "4") {
      nipStr = "04";
    } else if (nipStr == "5") {
      nipStr = "05";
    } else if (nipStr == "6") {
      nipStr = "06";
    } else if (nipStr == "7") {
      nipStr = "07";
    } else if (nipStr == "8") {
      nipStr = "08";
    } else if (nipStr == "9") {
      nipStr = "09";
    }

    return GestureDetector(
      onTap: () {
        final url =
            "https://github.com/nostr-protocol/nips/blob/master/$nipStr.md";
        WebViewRouter.open(context, url);
      },
      child: Text(
        nipStr,
        style: TextStyle(
          color: mainColor,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
