import "package:flutter/material.dart";
import "package:loure/client/nostr.dart";
import "package:loure/data/db.dart";

import "package:loure/consts/base.dart";
import "package:loure/main.dart";

class LogoutComponent extends StatefulWidget {
  const LogoutComponent({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LogoutComponentState();
  }
}

class _LogoutComponentState extends State<LogoutComponent> {
  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;

    return Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: hintColor,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING * 2,
          right: Base.BASE_PADDING * 2,
          top: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(
                bottom: Base.BASE_PADDING_HALF,
              ),
              child: const Text("Are you sure? All your data will be erased."),
            ),
            Container(
              margin: const EdgeInsets.only(
                bottom: Base.BASE_PADDING,
              ),
              child: const Text("Make sure you have saved your secret key."),
            ),
            TextButton(
              onPressed: handleLogoutTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    style:
                        TextStyle(color: themeData.textTheme.bodyMedium!.color),
                    "Proceed to Logout  ",
                  ),
                  Icon(
                    Icons.logout,
                    color: themeData.textTheme.bodyMedium!.color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void handleLogoutTap() {
    followingManager.reload();
    inboxManager.reload();

    contactListProvider.reload();
    eventReactionsProvider.clear();
    linkPreviewDataProvider.clear();
    bookmarkProvider.reload();
    emojiProvider.reload();

    settingProvider.removePrivateKey();
    DB.deleteAll(); // remove everything we have stored

    nostr = Nostr.empty(); // back to login screen

    settingProvider.reload();
    internalRouter.reload();

    settingProvider.saveAndNotifyListeners();

    Navigator.of(context).pop(); // close modal
  }
}
