import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:loure/component/webview_router.dart';
import 'package:loure/main.dart';
import 'package:loure/provider/link_preview_data_provider.dart';
import 'package:provider/provider.dart';

import 'package:loure/consts/base.dart';

class ContentLinkPreComponent extends StatefulWidget {
  String link;

  ContentLinkPreComponent({super.key, required this.link});

  @override
  State<StatefulWidget> createState() {
    return _ContentLinkPreComponent();
  }
}

class _ContentLinkPreComponent extends State<ContentLinkPreComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    return Selector<LinkPreviewDataProvider, PreviewData?>(
      builder: (context, data, child) {
        return Container(
          margin: const EdgeInsets.all(Base.BASE_PADDING),
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: themeData.shadowColor,
                offset: const Offset(0, 0),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: LinkPreview(
            linkStyle: const TextStyle(
              color: Colors.blue,
              decorationColor: Colors.blue,
            ),
            enableAnimation: true,
            onPreviewDataFetched: (data) {
              // Save preview data
              linkPreviewDataProvider.set(widget.link, data);
            },
            previewData: data,
            text: widget.link,
            width: mediaDataCache.size.width,
            onLinkPressed: (link) {
              WebViewRouter.open(context, link);
            },
          ),
        );
      },
      selector: (context, provider) {
        return provider.getPreviewData(widget.link);
      },
    );
  }
}
