import 'package:flutter/material.dart';
import 'package:loure/component/event/event_main_component.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/provider/single_event_provider.dart';
import 'package:loure/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import 'package:loure/client/event.dart';
import 'package:loure/consts/base.dart';

@deprecated
class GlobalEventItemComponent extends StatefulWidget {
  String eventId;

  GlobalEventItemComponent({super.key, required this.eventId});

  @override
  State<StatefulWidget> createState() {
    return _GlobalEventItemComponent();
  }
}

class _GlobalEventItemComponent extends State<GlobalEventItemComponent> {
  ScreenshotController screenshotController = ScreenshotController();

  Event? _event;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    return Selector<SingleEventProvider, Event?>(
      builder: (context, event, child) {
        if (event == null) {
          return Container(
            margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
            color: cardColor,
            height: 150,
            child: Center(
              child: Text(
                "loading",
                style: TextStyle(
                  color: hintColor,
                ),
              ),
            ),
          );
        }
        _event = event;

        var main = Screenshot(
          controller: screenshotController,
          child: Container(
            color: cardColor,
            margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
            padding: const EdgeInsets.only(
              top: Base.BASE_PADDING,
              // bottom: Base.BASE_PADDING,
            ),
            child: EventMainComponent(
              screenshotController: screenshotController,
              event: _event!,
              pagePubkey: null,
              textOnTap: jumpToThread,
            ),
          ),
        );

        return GestureDetector(
          onTap: jumpToThread,
          child: main,
        );
      },
      selector: (context, provider) {
        return provider.getEvent(widget.eventId);
      },
    );
  }

  void jumpToThread() {
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, _event);
  }
}
