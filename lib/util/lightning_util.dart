import "package:flutter/material.dart";
import "package:loure/component/lightning_qrcode_dialog.dart";
import "package:loure/util/platform_util.dart";
import "package:url_launcher/url_launcher.dart";

class LightningUtil {
  static Future<void> goToPay(
      final BuildContext context, final String invoiceCode) async {
    final link = "lightning:$invoiceCode";
    if (PlatformUtil.isPC() || PlatformUtil.isWeb()) {
      await LightningQrcodeDialog.show(context, link);
    } else {
      // if (Platform.isAndroid) {
      //   AndroidIntent intent = AndroidIntent(
      //     action: 'action_view',
      //     data: link,
      //   );
      //   await intent.launch();
      // } else {
      final url = Uri.parse(link);
      launchUrl(url);
      // }
    }
  }
}
