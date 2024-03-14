import 'dart:async';

import 'package:nostrmo/main.dart';

class SystemTimer {
  static int counter = 0;

  static Timer? timer;

  static void run() {
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      try {
        runTask();
        counter++;
      } catch (e) {
        print(e);
      }
    });
  }

  static void runTask() {
    // log("SystemTimer runTask");
    if (counter % 2 == 0) {
      // relayProvider.checkAndReconnect();
      if (counter > 4) {
        mentionMeNewProvider.queryNew();
        dmProvider.query();
      }
    } else {
      if (counter > 4) {
        followNewEventProvider.queryNew();
      }
    }
  }

  static void stopTask() {
    if (timer != null) {
      timer!.cancel();
    }
  }
}
