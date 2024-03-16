import "package:bot_toast/bot_toast.dart";
import "package:flutter/widgets.dart";

import "package:loure/main.dart";
import "package:loure/util/lightning_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/client/zap/zap.dart";

class ZapAction {
  static Future<void> handleZap(
      final BuildContext context, final int sats, final String pubkey,
      {final String? eventId,
      final String? pollOption,
      final String? comment}) async {
    final cancelFunc = BotToast.showLoading();
    try {
      final invoiceCode = await _doGenInvoiceCode(context, sats, pubkey,
          eventId: eventId, pollOption: pollOption, comment: comment);

      if (StringUtil.isBlank(invoiceCode)) {
        BotToast.showText(text: "Gen invoice code error.");
        return;
      }

      await LightningUtil.goToPay(context, invoiceCode!);
    } finally {
      cancelFunc.call();
    }
  }

  static Future<String?> genInvoiceCode(
      final BuildContext context, final int sats, final String pubkey,
      {final String? eventId,
      final String? pollOption,
      final String? comment}) async {
    final cancelFunc = BotToast.showLoading();
    try {
      return await _doGenInvoiceCode(context, sats, pubkey,
          eventId: eventId, pollOption: pollOption, comment: comment);
    } finally {
      cancelFunc.call();
    }
  }

  static Future<String?> _doGenInvoiceCode(
      final BuildContext context, final int sats, final String pubkey,
      {final String? eventId,
      final String? pollOption,
      final String? comment}) async {
    final metadata = await metadataLoader.load(pubkey);
    if (metadata.isBlank()) {
      BotToast.showText(text: "Metadata can not be found.");
      return null;
    }

    // lud06 like: LNURL1DP68GURN8GHJ7MRW9E6XJURN9UH8WETVDSKKKMN0WAHZ7MRWW4EXCUP0XPURJCEKXVERVDEJXCMKYDFHV43KX2HK8GT
    // lud16 like: pavol@rusnak.io
    // but some people set lud16 to lud06
    String? lnurl = metadata.lud06;
    String? lud16Link;

    if (StringUtil.isBlank(lnurl)) {
      if (StringUtil.isNotBlank(metadata.lud16)) {
        lnurl = Zap.getLnurlFromLud16(metadata.lud16!);
      }
    }
    if (StringUtil.isBlank(lnurl)) {
      BotToast.showText(text: "Lnurl ${"not found"}");
      return null;
    }
    // check if user set wrong
    if (lnurl!.contains("@")) {
      lnurl = Zap.getLnurlFromLud16(metadata.lud16!);
    }

    if (StringUtil.isBlank(lud16Link)) {
      if (StringUtil.isNotBlank(metadata.lud16)) {
        lud16Link = Zap.getLud16LinkFromLud16(metadata.lud16!);
      }
    }
    if (StringUtil.isBlank(lud16Link)) {
      if (StringUtil.isNotBlank(metadata.lud06)) {
        lud16Link = Zap.decodeLud06Link(metadata.lud06!);
      }
    }

    return await Zap.getInvoiceCode(
      lnurl: lnurl!,
      lud16Link: lud16Link!,
      sats: sats,
      recipientPubkey: pubkey,
      targetNostr: nostr,
      relays: nostr.relayList.read,
      eventId: eventId,
      pollOption: pollOption,
      comment: comment,
    );
  }
}
