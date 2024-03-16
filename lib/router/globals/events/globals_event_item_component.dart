import 'package:screenshot/screenshot.dart';
import 'package:flutter/material.dart';

import 'package:loure/component/event/event_main_component.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/main.dart';
import 'package:loure/util/router_util.dart';
import 'package:loure/client/event.dart';
import 'package:loure/consts/base.dart';

// ignore: must_be_immutable
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

  Future<Event?>? eventFuture;

  @override
  void initState() {
    super.initState();

    this.eventFuture = nostr.getByID(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    return FutureBuilder(
        future: this.eventFuture,
        initialData: null,
        builder: (context, snapshot) {
          final event = snapshot.data;
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
                event: event,
                pagePubkey: null,
                textOnTap: () {
                  RouterUtil.router(context, RouterPath.THREAD_DETAIL, event);
                },
              ),
            ),
          );

          return GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.THREAD_DETAIL, event);
            },
            child: main,
          );
        });
  }
}
