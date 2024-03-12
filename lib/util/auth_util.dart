import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';

import '../generated/l10n.dart';

class AuthUtil {
  static Future<bool> authenticate(BuildContext context, String reason,
      {bool showFail = true}) async {
    S s = S.of(context);
    var localAuth = LocalAuthentication();
    try {
      bool didAuthenticate = await localAuth.authenticate(
        localizedReason: reason,
      );
      if (!didAuthenticate && showFail) {
        BotToast.showText(text: "Verify failure");
      }
      return didAuthenticate;
    } catch (e) {
      BotToast.showText(text: "Verify error");
    }
    return false;
  }
}
