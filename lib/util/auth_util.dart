import "package:bot_toast/bot_toast.dart";
import "package:flutter/widgets.dart";
import "package:local_auth/local_auth.dart";

class AuthUtil {
  static Future<bool> authenticate(
      final BuildContext context, final String reason,
      {final bool showFail = true}) async {
    final localAuth = LocalAuthentication();
    try {
      final bool didAuthenticate = await localAuth.authenticate(
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
