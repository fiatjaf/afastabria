import "dart:async";

class SystemTimer {
  static int counter = 0;

  static Timer? timer;

  static void run() {
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(const Duration(seconds: 15), (final timer) {
      try {
        runTask();
        counter++;
      } catch (e) {
        print(e);
      }
    });
  }

  static void runTask() {
    // print("SystemTimer runTask");
  }

  static void stopTask() {
    if (timer != null) {
      timer!.cancel();
    }
  }
}
