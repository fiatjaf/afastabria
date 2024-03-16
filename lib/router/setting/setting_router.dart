import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_picker/flutter_font_picker.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:loure/client/nip02/cust_contact_list.dart';
import 'package:loure/client/filter.dart';
import 'package:loure/data/event_mem_box.dart';
import 'package:loure/router/index/account_manager_component.dart';
import 'package:loure/util/platform_util.dart';
import 'package:loure/util/router_util.dart';
import 'package:loure/util/when_stop_function.dart';
import 'package:provider/provider.dart';

import 'package:loure/client/event.dart';
import 'package:loure/client/event_kind.dart' as kind;
import 'package:loure/component/colors_selector_component.dart';
import 'package:loure/component/confirm_dialog.dart';
import 'package:loure/component/editor/text_input_dialog.dart';
import 'package:loure/component/enum_multi_selector_component.dart';
import 'package:loure/component/enum_selector_component.dart';
import 'package:loure/component/translate/translate_model_manager.dart';
import 'package:loure/consts/base.dart';
import 'package:loure/consts/base_consts.dart';
import 'package:loure/consts/image_services.dart';
import 'package:loure/consts/relay_mode.dart';
import 'package:loure/consts/theme_style.dart';
import 'package:loure/data/metadata.dart';
import 'package:loure/main.dart';
import 'package:loure/provider/setting_provider.dart';
import 'package:loure/util/auth_util.dart';
import 'package:loure/util/string_util.dart';
import 'package:loure/router/setting/setting_group_item_component.dart';
import 'package:loure/router/setting/setting_group_title_component.dart';

// ignore: must_be_immutable
class SettingRouter extends StatefulWidget {
  Function indexReload;

  SettingRouter({
    super.key,
    required this.indexReload,
  });

  @override
  State<StatefulWidget> createState() {
    return _SettingRouter();
  }
}

class _SettingRouter extends State<SettingRouter> with WhenStopFunction {
  void resetTheme() {
    widget.indexReload();
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var settingProvider = Provider.of<SettingProvider>(context);

    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;

    initOpenList();
    initCompressList();
    initDefaultList();
    initDefaultTabListTimeline();
    initDefaultTabListGlobal();

    initThemeStyleList();
    initFontEnumList();
    initImageServcieList();
    initTranslateLanguages();

    List<Widget> list = [];

    // list.add(SettingGroupItemComponent(
    //   name: "Image Compress",
    //   value: getCompressList(settingProvider.imgCompress).name,
    //   onTap: pickImageCompressList,
    // ));
    if (!PlatformUtil.isPC()) {
      list.add(SettingGroupItemComponent(
        name: "Privacy Lock",
        value: getLockOpenList(settingProvider.lockOpen).name,
        onTap: pickLockOpenList,
      ));
    }
    list.add(SettingGroupItemComponent(
      name: "Default index",
      value: getDefaultIndex(settingProvider.defaultIndex).name,
      onTap: pickDefaultIndex,
    ));
    List<EnumObj> defaultTabList = defaultTabListTimeline!;
    if (settingProvider.defaultIndex == 1) {
      defaultTabList = defaultTabListGlobal!;
    }
    list.add(SettingGroupItemComponent(
      name: "Default tab",
      value: getDefaultTab(defaultTabList, settingProvider.defaultTab).name,
      onTap: () {
        pickDefaultTab(defaultTabList);
      },
    ));

    list.add(SettingGroupTitleComponent(iconData: Icons.palette, title: "UI"));
    list.add(
      SettingGroupItemComponent(
        name: "Theme Style",
        value: getThemeStyle(settingProvider.themeStyle).name,
        onTap: pickThemeStyle,
      ),
    );
    list.add(SettingGroupItemComponent(
      name: "Theme Color",
      onTap: pickColor,
      child: Container(
        height: 28,
        width: 28,
        color: mainColor,
      ),
    ));
    list.add(SettingGroupItemComponent(
      name: "Font Family",
      value: getFontEnumResult(settingProvider.fontFamily),
      onTap: pickFontEnum,
    ));
    list.add(SettingGroupItemComponent(
      name: "Font Size",
      value: getFontSize(settingProvider.fontSize).name,
      onTap: pickFontSize,
    ));
    list.add(SettingGroupItemComponent(
      name: "Web Appbar",
      value: getOpenList(settingProvider.webviewAppbarOpen).name,
      onTap: pickWebviewAppbar,
    ));
    if (!PlatformUtil.isPC()) {
      list.add(SettingGroupItemComponent(
        name: "Table Mode",
        value: getOpenMode(settingProvider.tableMode).name,
        onTap: pickOpenMode,
      ));
    }

    list.add(
        SettingGroupTitleComponent(iconData: Icons.article, title: "Notes"));
    list.add(SettingGroupItemComponent(
      name: "Link preview",
      value: getOpenList(settingProvider.linkPreview).name,
      onTap: pickLinkPreview,
    ));
    if (!PlatformUtil.isPC()) {
      list.add(SettingGroupItemComponent(
        name: "Video preview in list",
        value: getOpenList(settingProvider.videoPreviewInList).name,
        onTap: pickVideoPreviewInList,
      ));
    }
    String? networkHintText = settingProvider.network;
    if (StringUtil.isBlank(networkHintText)) {
      networkHintText = "Please input Network";
    }
    Widget networkWidget = Text(
      networkHintText!,
      style: TextStyle(
        color: hintColor,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
    list.add(SettingGroupItemComponent(
      name: "Network",
      onTap: inputNetwork,
      child: networkWidget,
    ));
    list.add(SettingGroupItemComponent(
      name: "Image service",
      value: getImageServcie(settingProvider.imageService).name,
      onTap: pickImageServcie,
    ));
    list.add(SettingGroupItemComponent(
      name: "Limit Note Height",
      value: getOpenList(settingProvider.limitNoteHeight).name,
      onTap: pickLimitNoteHeight,
    ));
    list.add(SettingGroupItemComponent(
      name: "Forbid image",
      value: getOpenList(settingProvider.imagePreview).name,
      onTap: pickImagePreview,
    ));
    if (!PlatformUtil.isPC()) {
      list.add(SettingGroupItemComponent(
        name: "Forbid video",
        value: getOpenList(settingProvider.videoPreview).name,
        onTap: pickVideoPreview,
      ));
      list.add(SettingGroupItemComponent(
        name: "Translate",
        value: getOpenTranslate(settingProvider.openTranslate).name,
        onTap: pickOpenTranslate,
      ));
      if (settingProvider.openTranslate == OpenStatus.OPEN) {
        list.add(SettingGroupItemComponent(
          name: "Translate Source Language",
          value: settingProvider.translateSourceArgs,
          onTap: pickTranslateSource,
        ));
        list.add(SettingGroupItemComponent(
          name: "Translate Target Language",
          value: settingProvider.translateTarget,
          onTap: pickTranslateTarget,
        ));
      }
    }
    list.add(SettingGroupItemComponent(
      name: "Broadcast When Boost",
      value: getOpenList(settingProvider.broadcaseWhenBoost).name,
      onTap: pickBroadcaseWhenBoost,
    ));
    list.add(SettingGroupItemComponent(
      name: "Auto Open Sensitive Content",
      value: getOpenListDefault(settingProvider.autoOpenSensitive).name,
      onTap: pickAutoOpenSensitive,
    ));

    if (!PlatformUtil.isWeb()) {
      list.add(SettingGroupItemComponent(
        name: "Relay Mode",
        value: getRelayMode(settingProvider.relayMode).name,
        onTap: pickRelayModes,
      ));
      if (settingProvider.relayMode != RelayMode.BASE_MODE) {
        list.add(SettingGroupItemComponent(
          name: "Event Sign Check",
          value: getOpenListDefault(settingProvider.eventSignCheck).name,
          onTap: pickEventSignCheck,
        ));
      }
    }

    list.add(SettingGroupTitleComponent(iconData: Icons.source, title: "Data"));
    list.add(SettingGroupItemComponent(
      name: "Delete Account",
      nameColor: Colors.red,
      onTap: askToDeleteAccount,
    ));

    list.add(SliverToBoxAdapter(
      child: Container(
        height: 30,
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        title: Text(
          "Setting",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: Base.BASE_PADDING),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
        ),
        child: CustomScrollView(
          slivers: list,
        ),
      ),
    );
  }

  List<EnumObj>? openList;

  void initOpenList() {
    if (openList == null) {
      openList = [];
      openList!.add(EnumObj(OpenStatus.OPEN, "Open"));
      openList!.add(EnumObj(OpenStatus.CLOSE, "Close"));
    }
  }

  EnumObj getOpenList(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![0];
  }

  EnumObj getOpenListDefault(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![1];
  }

  List<EnumObj>? compressList;

  void initCompressList() {
    if (compressList == null) {
      compressList = [];
      compressList!.add(EnumObj(100, "Don't compress"));
      compressList!.add(EnumObj(90, "90%"));
      compressList!.add(EnumObj(80, "80%"));
      compressList!.add(EnumObj(70, "70%"));
      compressList!.add(EnumObj(60, "60%"));
      compressList!.add(EnumObj(50, "50%"));
      compressList!.add(EnumObj(40, "40%"));
    }
  }

  Future<void> pickImageCompressList() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, compressList!);
    if (resultEnumObj != null) {
      settingProvider.imgCompress = resultEnumObj.value;
    }
  }

  EnumObj getCompressList(int compress) {
    for (var eo in compressList!) {
      if (eo.value == compress) {
        return eo;
      }
    }
    return compressList![0];
  }

  List<EnumObj>? lockOpenList;

  EnumObj getLockOpenList(int lockOpen) {
    if (lockOpen == OpenStatus.OPEN) {
      return openList![0];
    }
    return openList![1];
  }

  Future<void> pickLockOpenList() async {
    List<EnumObj> newLockOpenList = [];
    newLockOpenList.add(openList![1]);

    var localAuth = LocalAuthentication();
    List<BiometricType> availableBiometrics =
        await localAuth.getAvailableBiometrics();
    if (availableBiometrics.isNotEmpty) {
      newLockOpenList.add(openList![0]);
    }

    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, newLockOpenList);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == OpenStatus.CLOSE) {
        bool didAuthenticate = await AuthUtil.authenticate(
            context, "Please authenticate to turn off the privacy lock");
        if (didAuthenticate) {
          settingProvider.lockOpen = resultEnumObj.value;
        }
        settingProvider.lockOpen = resultEnumObj.value;
      } else if (resultEnumObj.value == OpenStatus.OPEN) {
        bool didAuthenticate = await AuthUtil.authenticate(
            context, "Please authenticate to turn on the privacy lock");
        if (didAuthenticate) {
          settingProvider.lockOpen = resultEnumObj.value;
        }
      }
    }
  }

  List<EnumObj>? defaultIndexList;

  void initDefaultList() {
    if (defaultIndexList == null) {
      defaultIndexList = [];
      defaultIndexList!.add(EnumObj(0, "Timeline"));
      defaultIndexList!.add(EnumObj(1, "Global"));
    }
  }

  Future<void> pickDefaultIndex() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, defaultIndexList!);
    if (resultEnumObj != null) {
      settingProvider.defaultIndex = resultEnumObj.value;
      resetTheme();
    }
  }

  EnumObj getDefaultIndex(int? value) {
    for (var eo in defaultIndexList!) {
      if (eo.value == value) {
        return eo;
      }
    }
    return defaultIndexList![0];
  }

  List<EnumObj>? defaultTabListTimeline;

  void initDefaultTabListTimeline() {
    if (defaultTabListTimeline == null) {
      defaultTabListTimeline = [];
      defaultTabListTimeline!.add(EnumObj(0, "Posts"));
      defaultTabListTimeline!.add(EnumObj(1, "Posts & Replies"));
      defaultTabListTimeline!.add(EnumObj(2, "Mentions"));
    }
  }

  List<EnumObj>? defaultTabListGlobal;

  void initDefaultTabListGlobal() {
    if (defaultTabListGlobal == null) {
      defaultTabListGlobal = [];
      defaultTabListGlobal!.add(EnumObj(0, "Notes"));
      defaultTabListGlobal!.add(EnumObj(1, "Users"));
      defaultTabListGlobal!.add(EnumObj(2, "Topics"));
    }
  }

  Future<void> pickDefaultTab(List<EnumObj> list) async {
    EnumObj? resultEnumObj = await EnumSelectorComponent.show(context, list);
    if (resultEnumObj != null) {
      settingProvider.defaultTab = resultEnumObj.value;
      resetTheme();
    }
  }

  EnumObj getDefaultTab(List<EnumObj> list, int? value) {
    for (var eo in list) {
      if (eo.value == value) {
        return eo;
      }
    }
    return list[0];
  }

  List<EnumObj>? themeStyleList;

  void initThemeStyleList() {
    if (themeStyleList == null) {
      themeStyleList = [];
      themeStyleList?.add(EnumObj(ThemeStyle.AUTO, "Follow System"));
      themeStyleList?.add(EnumObj(ThemeStyle.LIGHT, "Light"));
      themeStyleList?.add(EnumObj(ThemeStyle.DARK, "Dark"));
    }
  }

  Future<void> pickThemeStyle() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, themeStyleList!);
    if (resultEnumObj != null) {
      settingProvider.themeStyle = resultEnumObj.value;
      resetTheme();
    }
  }

  EnumObj getThemeStyle(int themeStyle) {
    for (var eo in themeStyleList!) {
      if (eo.value == themeStyle) {
        return eo;
      }
    }
    return themeStyleList![0];
  }

  Future<void> pickColor() async {
    Color? color = await ColorSelectorComponent.show(context);
    if (color != null) {
      settingProvider.themeColor = color.value;
      resetTheme();
    }
  }

  List<EnumObj>? fontEnumList;

  void initFontEnumList() {
    if (fontEnumList == null) {
      fontEnumList = [];
      fontEnumList!.add(EnumObj(false, "Default Font Family"));
      fontEnumList!.add(EnumObj(true, "Custom Font Family"));
    }
  }

  String getFontEnumResult(String? fontFamily) {
    if (StringUtil.isNotBlank(fontFamily)) {
      return fontFamily!;
    }
    return fontEnumList![0].name;
  }

  Future pickFontEnum() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, fontEnumList!);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == true) {
        pickFont();
      } else {
        settingProvider.fontFamily = null;
        resetTheme();
      }
    }
  }

  void pickFont() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FontPicker(
          onFontChanged: (PickerFont font) {
            settingProvider.fontFamily = font.fontFamily;
            resetTheme();
          },
        ),
      ),
    );
  }

  List<EnumObj> fontSizeList = [
    EnumObj(20.0, "20"),
    EnumObj(19.0, "19"),
    EnumObj(18.0, "18"),
    EnumObj(17.0, "17"),
    EnumObj(16.0, "16"),
    EnumObj(15.0, "15"),
    EnumObj(14.0, "14"),
    EnumObj(13.0, "13"),
    EnumObj(12.0, "12"),
  ];

  EnumObj getFontSize(double value) {
    for (var eo in fontSizeList) {
      if (eo.value == value) {
        return eo;
      }
    }
    return fontSizeList[1];
  }

  Future<void> pickFontSize() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, fontSizeList);
    if (resultEnumObj != null) {
      settingProvider.fontSize = resultEnumObj.value;
      resetTheme();
    }
  }

  Future<void> pickLinkPreview() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.linkPreview = resultEnumObj.value;
    }
  }

  Future<void> pickVideoPreviewInList() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.videoPreviewInList = resultEnumObj.value;
    }
  }

  inputNetwork() async {
    var text = await TextInputDialog.show(
      context,
      "${"Please input"} ${"Network"}\nSOCKS5/SOCKS4/PROXY username:password@host:port",
      value: settingProvider.network,
    );
    settingProvider.network = text;
    BotToast.showText(
        text: "The network will take effect the next time the app is launched");
  }

  List<EnumObj>? imageServcieList;

  void initImageServcieList() {
    if (imageServcieList == null) {
      imageServcieList = [];
      imageServcieList!
          .add(EnumObj(ImageServices.NOSTRIMG_COM, ImageServices.NOSTRIMG_COM));
      imageServcieList!.add(
          EnumObj(ImageServices.NOSTRFILES_DEV, ImageServices.NOSTRFILES_DEV));
      imageServcieList!
          .add(EnumObj(ImageServices.NOSTR_BUILD, ImageServices.NOSTR_BUILD));
      imageServcieList!.add(
          EnumObj(ImageServices.POMF2_LAIN_LA, ImageServices.POMF2_LAIN_LA));
      // imageServcieList!
      //     .add(EnumObj(ImageServices.VOID_CAT, ImageServices.VOID_CAT));
    }
  }

  EnumObj getImageServcie(String? o) {
    for (var eo in imageServcieList!) {
      if (eo.value == o) {
        return eo;
      }
    }
    return imageServcieList![0];
  }

  Future<void> pickImageServcie() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, imageServcieList!);
    if (resultEnumObj != null) {
      settingProvider.imageService = resultEnumObj.value;
    }
  }

  pickLimitNoteHeight() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.limitNoteHeight = resultEnumObj.value;
    }
  }

  pickImagePreview() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.imagePreview = resultEnumObj.value;
    }
  }

  pickVideoPreview() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.videoPreview = resultEnumObj.value;
    }
  }

  EventMemBox waitingDeleteEventBox = EventMemBox(sortAfterAdd: false);

  CancelFunc? deleteAccountLoadingCancel;

  askToDeleteAccount() async {
    var result = await ConfirmDialog.show(context, "Delete_Account_Tips");
    if (result == true) {
      deleteAccountLoadingCancel = BotToast.showLoading();
      try {
        whenStopMS = 2000;
        waitingDeleteEventBox.clear();

        // use a blank metadata to update it
        nostr.sendMetadata(Metadata.blank(""));

        // use a blank contact list to update it
        var blankContactList = CustContactList();
        nostr.sendContactList(blankContactList, "");

        var filter = Filter(authors: [
          nostr.publicKey
        ], kinds: [
          kind.EventKind.TEXT_NOTE,
          kind.EventKind.REPOST,
          kind.EventKind.GENERIC_REPOST,
        ]);

        pool.subscribeManyEose(["wss://relay.nostr.band"], [filter],
            onEvent: onDeletedEventReceive);
      } catch (e) {
        log("delete account error ${e.toString()}");
      }
    }
  }

  onDeletedEventReceive(Event event) {
    print(event.toJson());
    waitingDeleteEventBox.add(event);
    whenStop(handleDeleteEvent);
  }

  void handleDeleteEvent() {
    try {
      List<Event> all = waitingDeleteEventBox.all();
      List<String> ids = [];
      for (var event in all) {
        ids.add(event.id);

        if (ids.length > 20) {
          nostr.deleteEvents(ids);
          ids.clear();
        }
      }

      if (ids.isNotEmpty) {
        nostr.deleteEvents(ids);
      }
    } finally {
      var index = settingProvider.privateKeyIndex;
      if (index != null) {
        AccountManagerComponentState.onLogoutTap(index,
            routerBack: true, context: context);
        metadataLoader.clear();
      }
      if (deleteAccountLoadingCancel != null) {
        deleteAccountLoadingCancel!.call();
      }
    }
  }

  List<EnumObj>? translateLanguages;

  void initTranslateLanguages() {
    if (translateLanguages == null) {
      translateLanguages = [];
      for (var tl in TranslateLanguage.values) {
        translateLanguages!.add(EnumObj(tl.bcpCode, tl.bcpCode));
      }
    }
  }

  EnumObj getOpenTranslate(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![1];
  }

  pickOpenTranslate() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      await handleTranslateModel(openTranslate: resultEnumObj.value);
      settingProvider.openTranslate = resultEnumObj.value;
    }
  }

  pickTranslateSource() async {
    var translateSourceArgs = settingProvider.translateSourceArgs;
    List<EnumObj> values = [];
    if (StringUtil.isNotBlank(translateSourceArgs)) {
      var strs = translateSourceArgs!.split(",");
      for (var str in strs) {
        values.add(EnumObj(str, str));
      }
    }
    List<EnumObj>? resultEnumObjs = await EnumMultiSelectorComponent.show(
        context, translateLanguages!, values);
    if (resultEnumObjs != null) {
      List<String> resultStrs = [];
      for (var value in resultEnumObjs) {
        resultStrs.add(value.value);
      }
      var text = resultStrs.join(",");
      await handleTranslateModel(translateSourceArgs: text);
      settingProvider.translateSourceArgs = text;
    }
  }

  pickTranslateTarget() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, translateLanguages!);
    if (resultEnumObj != null) {
      await handleTranslateModel(translateTarget: resultEnumObj.value);
      settingProvider.translateTarget = resultEnumObj.value;
    }
  }

  Future<void> handleTranslateModel(
      {int? openTranslate,
      String? translateTarget,
      String? translateSourceArgs}) async {
    openTranslate = openTranslate ?? settingProvider.openTranslate;
    translateTarget = translateTarget ?? settingProvider.translateTarget;
    translateSourceArgs =
        translateSourceArgs ?? settingProvider.translateSourceArgs;

    if (openTranslate == OpenStatus.OPEN &&
        StringUtil.isNotBlank(translateTarget) &&
        StringUtil.isNotBlank(translateSourceArgs)) {
      List<String> bcpCodes = translateSourceArgs!.split(",");
      bcpCodes.add(translateTarget!);

      var translateModelManager = TranslateModelManager.getInstance();
      BotToast.showText(text: "Begin_to_download_translate_model");
      var cancelFunc = BotToast.showLoading();
      try {
        await translateModelManager.checkAndDownloadTargetModel(bcpCodes);
      } finally {
        cancelFunc.call();
      }
    }
  }

  pickBroadcaseWhenBoost() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.broadcaseWhenBoost = resultEnumObj.value;
    }
  }

  EnumObj getAutoOpenSensitive(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![1];
  }

  pickAutoOpenSensitive() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.autoOpenSensitive = resultEnumObj.value;
    }
  }

  pickWebviewAppbar() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.webviewAppbarOpen = resultEnumObj.value;
    }
  }

  getOpenMode(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    if (PlatformUtil.isTableModeWithoutSetting()) {
      return openList![0];
    }
    return openList![1];
  }

  pickOpenMode() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.tableMode = resultEnumObj.value;
      resetTheme();
    }
  }

  List<EnumObj>? relayModes;

  List<EnumObj> getRelayModes() {
    if (relayModes == null) {
      relayModes = [];
      relayModes!.add(EnumObj(RelayMode.FAST_MODE, "Fast Mode"));
      relayModes!.add(EnumObj(RelayMode.BASE_MODE, "Base Mode"));
    }
    return relayModes!;
  }

  EnumObj getRelayMode(int? o) {
    var list = getRelayModes();
    for (var item in list) {
      if (item.value == o) {
        return item;
      }
    }

    return list[0];
  }

  pickRelayModes() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, getRelayModes());
    if (resultEnumObj != null) {
      settingProvider.relayMode = resultEnumObj.value;
    }
  }

  pickEventSignCheck() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.eventSignCheck = resultEnumObj.value;
    }
  }
}
