import "package:loure/client/event.dart";
import "package:loure/util/dio_util.dart";

class SendBox {
  static Future<void> submit(
      final Event event, final List<String> relays) async {
    var link = "https://sendbox_api.nostrmo.com/api/msg/submit?";
    for (var i = 0; i < relays.length && i < 6; i++) {
      final relayAddr = relays[i];
      link += "&r=$relayAddr";
    }

    await DioUtil.post(link, event.toJson());
  }
}
