import "package:loure/client/event_kind.dart" as kind;
import "package:loure/util/spider_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/client/event.dart";

class ZapNumUtil {
  static int getNumFromZapEvent(final Event event) {
    if (event.kind == kind.EventKind.ZAP) {
      for (final tag in event.tags) {
        if (tag.length > 1) {
          final tagType = tag[0];
          if (tagType == "bolt11") {
            final zapStr = tag[1];
            return getNumFromStr(zapStr);
          }
        }
      }
    }

    return 0;
  }

  static int getNumFromStr(final String zapStr) {
    final numStr = SpiderUtil.subUntil(zapStr, "lnbc", "1p");
    if (StringUtil.isNotBlank(numStr)) {
      final numStrLength = numStr.length;
      if (numStrLength > 1) {
        final lastStr = numStr.substring(numStr.length - 1);
        final pureNumStr = numStr.substring(0, numStr.length - 1);
        final pureNum = int.tryParse(pureNumStr);
        if (pureNum != null) {
          if (lastStr == "p") {
            return (pureNum * 0.0001).round();
          } else if (lastStr == "n") {
            return (pureNum * 0.1).round();
          } else if (lastStr == "u") {
            return (pureNum * 100).round();
          } else if (lastStr == "m") {
            return (pureNum * 100000).round();
          }
        }
      }
    }

    return 0;
  }
}
