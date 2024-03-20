import "package:bot_toast/bot_toast.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "package:loure/component/editor/text_input_dialog.dart";
import "package:loure/component/name_component.dart";
import "package:loure/component/point_component.dart";
import "package:loure/data/metadata.dart";
import "package:loure/provider/setting_provider.dart";
import "package:loure/util/router_util.dart";
import "package:loure/client/nostr.dart";

import "package:loure/client/client_utils/keys.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/component/confirm_dialog.dart";
import "package:loure/component/image_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/data/dm_session_info_db.dart";
import "package:loure/data/event_db.dart";
import "package:loure/main.dart";
import "package:loure/util/string_util.dart";
import "package:loure/router/index/index_drawer_content.dart";

class AccountManagerComponent extends StatefulWidget {
  const AccountManagerComponent({super.key});

  @override
  State<StatefulWidget> createState() {
    return AccountManagerComponentState();
  }
}

class AccountManagerComponentState extends State<AccountManagerComponent> {
  List<String> publicKeyList = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final settingProvider = Provider.of<SettingProvider>(context);
    settingProvider.publicKeyList().then((final list) {
      this.setState(() {
        this.publicKeyList = list;
      });
    });
  }

  @override
  Widget build(final BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);

    final themeData = Theme.of(context);
    final hintColor = themeData.hintColor;
    final btnTextColor = themeData.textTheme.bodyMedium!.color;

    List<Widget> list = [];
    list.add(Container(
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
      child: IndexDrawerItem(
        iconData: Icons.account_box,
        name: "Account Manager",
        onTap: () {},
      ),
    ));

    for (var idx = 0; idx < publicKeyList.length; idx++) {
      final key = publicKeyList[idx];
      list.add(AccountManagerItemComponent(
        publicKey: key,
        isCurrent: settingProvider.privateKeyIndex == idx,
        onLogin: () {
          this.onLoginTap(idx);
        },
        onLogout: () {
          this.onLogoutTap(idx, idx == publicKeyList.length - 1,
              context: context);
        },
      ));
    }

    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING * 2,
        right: Base.BASE_PADDING * 2,
      ),
      width: double.maxFinite,
      child: TextButton(
        onPressed: addAccount,
        style: ButtonStyle(
          side: MaterialStateProperty.all(BorderSide(
            width: 1,
            color: hintColor.withOpacity(0.4),
          )),
        ),
        child: Text(
          "Add Account",
          style: TextStyle(color: btnTextColor),
        ),
      ),
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list,
    );
  }

  Future<void> addAccount() async {
    var privateKey = await TextInputDialog.show(context, "Input secret key",
        valueCheck: addAccountCheck);
    if (StringUtil.isNotBlank(privateKey)) {
      final result = await ConfirmDialog.show(context, "Add account and login");
      if (result == true) {
        if (Nip19.isPrivateKey(privateKey!)) {
          privateKey = Nip19.decode(privateKey);
        }
        // logout current and login new
        final oldIndex = settingProvider.privateKeyIndex;
        final newIndex =
            await settingProvider.addAndChangePrivateKey(privateKey);
        if (oldIndex != newIndex) {
          clearCurrentMemInfo();
          this.doLogin();
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          settingProvider.notifyListeners();
          RouterUtil.back(context);
        }
      }
    }
  }

  bool addAccountCheck(final BuildContext p1, String privateKey) {
    if (StringUtil.isNotBlank(privateKey)) {
      if (Nip19.isPrivateKey(privateKey)) {
        privateKey = Nip19.decode(privateKey);
      }

      // try to gen publicKey check the formate
      try {
        getPublicKey(privateKey);
      } catch (e) {
        BotToast.showText(text: "Wrong Private key format");
        return false;
      }
    }

    return true;
  }

  void doLogin() async {
    nostr = Nostr((await settingProvider.privateKey())!);
    nostr.init();
  }

  void onLoginTap(final int index) async {
    if (settingProvider.privateKeyIndex != index) {
      clearCurrentMemInfo();
      settingProvider.privateKeyIndex = index;
      this.doLogin();
      settingProvider.saveAndNotifyListeners();
      RouterUtil.back(context);
    }
  }

  void onLogoutTap(final int index, final bool isLast,
      {final bool routerBack = true, final BuildContext? context}) {
    if (index == settingProvider.privateKeyIndex) {
      clearLocalData(index);
      clearCurrentMemInfo();
      settingProvider.privateKeyIndex = isLast ? index - 1 : index;
      this.doLogin();
      settingProvider.saveAndNotifyListeners();
    }

    if (routerBack && context != null) {
      RouterUtil.back(context);
    }
  }

  static void clearCurrentMemInfo() {
    mentionMeProvider.clear();
    mentionMeNewProvider.clear();
    dmProvider.clear();
    noticeProvider.clear();
    contactListProvider.clear();

    eventReactionsProvider.clear();
    linkPreviewDataProvider.clear();
    bookmarkProvider.clear();
    emojiProvider.clear();
  }

  static void clearLocalData(final int index) {
    // remove private key
    settingProvider.removeKey(index);
    // clear local db
    DMSessionInfoDB.deleteAll(index);
    EventDB.deleteAll(index);
    // MetadataDB.deleteAll(); // MetadataDB don't delete here, but delete in setting
  }
}

// ignore: must_be_immutable
class AccountManagerItemComponent extends StatelessWidget {
  const AccountManagerItemComponent({
    required this.isCurrent,
    required this.publicKey,
    required this.onLogin,
    required this.onLogout,
    super.key,
  });

  final bool isCurrent;
  final String publicKey;
  final Function() onLogin;
  final Function() onLogout;

  static const double IMAGE_WIDTH = 26;
  static const double LINE_HEIGHT = 44;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    // var hintColor = themeData.hintColor;
    Color? cardColor = themeData.cardColor;
    if (cardColor == Colors.white) {
      cardColor = Colors.grey[300];
    }

    return FutureBuilder(
        future: metadataLoader.load(this.publicKey),
        initialData: Metadata.blank(this.publicKey),
        builder: (final context, final snapshot) {
          final metadata = snapshot.data!;

          const Color currentColor = Colors.green;
          List<Widget> list = [];

          final nip19PubKey = Nip19.encodePubKey(metadata.pubkey);

          Widget? imageWidget;
          if (metadata.picture != null && metadata.picture != "") {
            imageWidget = ImageComponent(
              imageUrl: metadata.picture!,
              width: IMAGE_WIDTH,
              height: IMAGE_WIDTH,
              fit: BoxFit.cover,
              placeholder: (final context, final url) =>
                  const CircularProgressIndicator(),
            );
          }

          list.add(Container(
            width: 24,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 15,
              child: this.isCurrent
                  ? PointComponent(
                      width: 15,
                      color: currentColor,
                    )
                  : null,
            ),
          ));

          list.add(Container(
            width: IMAGE_WIDTH,
            height: IMAGE_WIDTH,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
              color: Colors.grey,
            ),
            child: imageWidget,
          ));

          list.add(Container(
            margin: const EdgeInsets.only(left: 5, right: 5),
            child: NameComponent(
              pubkey: metadata.pubkey,
              metadata: metadata,
            ),
          ));

          list.add(Expanded(
              child: Container(
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING_HALF,
              right: Base.BASE_PADDING_HALF,
              top: 4,
              bottom: 4,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              nip19PubKey,
              overflow: TextOverflow.ellipsis,
            ),
          )));

          list.add(GestureDetector(
            onTap: onLogout,
            child: Container(
              padding: const EdgeInsets.only(left: 5),
              height: LINE_HEIGHT,
              child: const Icon(Icons.logout),
            ),
          ));

          return GestureDetector(
            onTap: onLogin,
            behavior: HitTestBehavior.translucent,
            child: Container(
              height: LINE_HEIGHT,
              width: double.maxFinite,
              padding: const EdgeInsets.only(
                left: Base.BASE_PADDING * 2,
                right: Base.BASE_PADDING * 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: list,
              ),
            ),
          );
        });
  }
}
