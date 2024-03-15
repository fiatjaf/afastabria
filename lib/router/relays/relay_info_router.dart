import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:nostrmo/component/name_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/component/image_component.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/client/relay/relay_info.dart';

class RelayInfoRouter extends StatefulWidget {
  const RelayInfoRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RelayInfoRouter();
  }
}

class _RelayInfoRouter extends State<RelayInfoRouter> {
  double IMAGE_WIDTH = 45;
  RelayInfo? info;
  String? url;

  @override
  void initState() {
    super.initState();

    var url = RouterUtil.routerArgs(context);
    if (url == null || url is! String) {
      RouterUtil.back(context);
      return;
    }

    http.get(Uri.parse(url).replace(scheme: 'https'),
        headers: {'Accept': 'application/nostr+json'}).then((response) {
      this.setState(() {
        this.url = url;
        this.info = RelayInfo.fromJson(jsonDecode(response.body) as Map);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (this.info == null) return Container();

    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
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

    list.add(RelayInfoItemComponent(
      title: "Owner",
      child: Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
          List<Widget> list = [];

          Widget? imageWidget;
          if (metadata != null) {
            imageWidget = ImageComponent(
              imageUrl: metadata.picture!,
              width: IMAGE_WIDTH,
              height: IMAGE_WIDTH,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
            );
          }
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
            child: NameComponnet(
              pubkey: this.info!.pubKey,
              metadata: metadata,
            ),
          ));

          return GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.USER, this.info!.pubKey);
            },
            child: Row(
              children: list,
            ),
          );
        },
        selector: (context, provider) {
          return provider.getMetadata(this.info!.pubKey);
        },
      ),
    ));

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
    for (var nip in this.info!.nips) {
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
  String title;

  Widget child;

  RelayInfoItemComponent({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
  dynamic nip;

  NipComponent({super.key, required this.nip});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

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
        var url =
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
