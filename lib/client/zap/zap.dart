import "dart:convert";

import "package:bech32/bech32.dart";

import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart" as kind;
import "package:loure/util/dio_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/client/nostr.dart";
import "package:loure/client/zap/lnurl_response.dart";

class Zap {
  static String decodeLud06Link(final String lud06) {
    final decoder = Bech32Decoder();
    final bech32Result = decoder.convert(lud06, 2000);
    final data = NIP19.convertBits(bech32Result.data, 5, 8, false);
    return utf8.decode(data);
  }

  static String? getLud16LinkFromLud16(final String lud16) {
    final strs = lud16.split("@");
    if (strs.length < 2) {
      return null;
    }

    final username = strs[0];
    final domainname = strs[1];

    return "https://$domainname/.well-known/lnurlp/$username";
  }

  static String? getLnurlFromLud16(final String lud16) {
    final link = getLud16LinkFromLud16(lud16);
    List<int> data = utf8.encode(link!);
    data = NIP19.convertBits(data, 8, 5, true);

    final encoder = Bech32Encoder();
    final Bech32 input = Bech32("lnurl", data);
    final lnurl = encoder.convert(input, 2000);

    return lnurl.toUpperCase();
  }

  static Future<LnurlResponse?> getLnurlResponse(final String link) async {
    final responseMap = await DioUtil.get(link);
    if (responseMap != null && StringUtil.isNotBlank(responseMap["callback"])) {
      return LnurlResponse.fromJson(responseMap);
    }

    return null;
  }

  static Future<String?> getInvoiceCode({
    required final String lnurl,
    required final String lud16Link,
    required final int sats,
    required final String recipientPubkey,
    required final Nostr targetNostr,
    required final List<String> relays,
    final String? eventId,
    final String? pollOption,
    String? comment,
  }) async {
    // var lnurlLink = decodeLud06Link(lnurl);
    final lnurlResponse = await getLnurlResponse(lud16Link);
    if (lnurlResponse == null) {
      return null;
    }

    var callback = lnurlResponse.callback!;
    if (callback.contains("?")) {
      callback += "&";
    } else {
      callback += "?";
    }

    final amount = sats * 1000;
    callback += "amount=$amount";

    String eventContent = "";
    if (StringUtil.isNotBlank(comment)) {
      final commentNum = lnurlResponse.commentAllowed;
      if (commentNum != null) {
        if (commentNum < comment!.length) {
          comment = comment.substring(0, commentNum);
        }
        callback += "&comment=${Uri.encodeQueryComponent(comment)}";
        eventContent = comment;
      }
    }

    final tags = [
      ["relays", ...relays],
      ["amount", amount.toString()],
      ["lnurl", lnurl],
      ["p", recipientPubkey],
    ];
    if (StringUtil.isNotBlank(eventId)) {
      tags.add(["e", eventId!]);
    }
    if (StringUtil.isNotBlank(pollOption)) {
      tags.add(["poll_option", pollOption!]);
    }
    final event = Event.finalize(
        targetNostr.privateKey, kind.EventKind.ZAP_REQUEST, tags, eventContent);
    print(jsonEncode(event));
    final eventStr = Uri.encodeQueryComponent(jsonEncode(event));
    callback += "&nostr=$eventStr";
    callback += "&lnurl=$lnurl";

    print("getInvoice callback $callback");

    final responseMap = await DioUtil.get(callback);
    if (responseMap != null && StringUtil.isNotBlank(responseMap["pr"])) {
      return responseMap["pr"];
    }

    return null;
  }
}
