import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:bip340/bip340.dart" as bip340;
import "package:loure/client/client_utils/keys.dart";

import "package:loure/main.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/base_consts.dart";
import "package:loure/consts/theme_style.dart";
import "package:loure/util/string_util.dart";
import "package:loure/provider/data_util.dart";

class SettingProvider extends ChangeNotifier {
  late SettingData _settingData;
  late CustomSecureStorage _secureStorage;

  String? privateKey;
  String? publicKey;

  Future<void> init() async {
    try {
      _settingData = SettingData.fromJson(
          jsonDecode(sharedPreferences.getString(DataKey.SETTING)!));
    } catch (err) {
      _settingData = SettingData();
    }

    _secureStorage = CustomSecureStorage();

    this.privateKey = await this._secureStorage.read("secretkey");
    if (this.privateKey == null || !keyIsValid(this.privateKey!)) {
      this.privateKey = null;
    }
    this.publicKey =
        this.privateKey != null ? bip340.getPublicKey(this.privateKey!) : null;
  }

  Future<void> reload() async {
    await init();
    this._reloadTranslateSourceArgs();
    notifyListeners();
  }

  Future<void> setPrivateKey(final String sk,
      {final bool updateUI = false}) async {
    this._secureStorage.write("secretkey", sk);
    this.privateKey = sk;
    this.publicKey = bip340.getPublicKey(sk);

    saveAndNotifyListeners(updateUI: updateUI);
  }

  Future<void> removePrivateKey() async {
    _secureStorage.write("secretkey", "");
    this.privateKey = null;
    this.publicKey = null;
    this.saveAndNotifyListeners();
  }

  SettingData get settingData => _settingData;

  /// open lock
  int get lockOpen => _settingData.lockOpen;

  int? get defaultIndex => _settingData.defaultIndex;
  int? get defaultTab => _settingData.defaultTab;

  int get linkPreview => _settingData.linkPreview != null
      ? _settingData.linkPreview!
      : OpenStatus.OPEN;

  int get videoPreviewInList => _settingData.videoPreviewInList != null
      ? _settingData.videoPreviewInList!
      : OpenStatus.CLOSE;

  String? get network => _settingData.network;
  String? get imageService => _settingData.imageService;
  int? get videoPreview => _settingData.videoPreview;
  int? get imagePreview => _settingData.imagePreview;

  /// image compress
  int get imgCompress => _settingData.imgCompress;

  /// theme style
  int get themeStyle => _settingData.themeStyle;

  /// theme color
  int? get themeColor => _settingData.themeColor;

  /// fontFamily
  String? get fontFamily => _settingData.fontFamily;

  int? get openTranslate => _settingData.openTranslate;

  static const ALL_SUPPORT_LANGUAGES =
      "af,sq,ar,be,bn,bg,ca,zh,hr,cs,da,nl,en,eo,et,fi,fr,gl,ka,de,el,gu,ht,he,hi,hu,is,id,ga,it,ja,kn,ko,lv,lt,mk,ms,mt,mr,no,fa,pl,pt,ro,ru,sk,sl,es,sw,sv,tl,ta,te,th,tr,uk,ur,vi,cy";

  String? get translateSourceArgs {
    if (StringUtil.isNotBlank(_settingData.translateSourceArgs)) {
      return _settingData.translateSourceArgs!;
    }
    return null;
  }

  String? get translateTarget => _settingData.translateTarget;

  final Map<String, int> _translateSourceArgsMap = {};

  void _reloadTranslateSourceArgs() {
    _translateSourceArgsMap.clear();
    final args = _settingData.translateSourceArgs;
    if (StringUtil.isNotBlank(args)) {
      final argStrs = args!.split(",");
      for (final argStr in argStrs) {
        if (StringUtil.isNotBlank(argStr)) {
          _translateSourceArgsMap[argStr] = 1;
        }
      }
    }
  }

  bool translateSourceArgsCheck(final String str) {
    return _translateSourceArgsMap[str] != null;
  }

  int? get broadcaseWhenBoost =>
      _settingData.broadcaseWhenBoost ?? OpenStatus.OPEN;

  double get fontSize =>
      _settingData.fontSize ??
      (PlatformUtil.isTableMode()
          ? Base.BASE_FONT_SIZE_PC
          : Base.BASE_FONT_SIZE);

  int get webviewAppbarOpen => _settingData.webviewAppbarOpen;

  int? get tableMode => _settingData.tableMode;

  int? get autoOpenSensitive => _settingData.autoOpenSensitive;

  int? get relayMode => _settingData.relayMode;

  int? get eventSignCheck => _settingData.eventSignCheck;

  int? get limitNoteHeight => _settingData.limitNoteHeight;

  set settingData(final SettingData o) {
    this._settingData = o;
    this.saveAndNotifyListeners();
  }

  /// open lock
  set lockOpen(final int o) {
    this._settingData.lockOpen = o;
    this.saveAndNotifyListeners();
  }

  set defaultIndex(final int? o) {
    this._settingData.defaultIndex = o;
    this.saveAndNotifyListeners();
  }

  set defaultTab(final int? o) {
    this._settingData.defaultTab = o;
    this.saveAndNotifyListeners();
  }

  set linkPreview(final int o) {
    this._settingData.linkPreview = o;
    this.saveAndNotifyListeners();
  }

  set videoPreviewInList(final int o) {
    this._settingData.videoPreviewInList = o;
    this.saveAndNotifyListeners();
  }

  set network(final String? o) {
    this._settingData.network = o;
    this.saveAndNotifyListeners();
  }

  set imageService(final String? o) {
    this._settingData.imageService = o;
    this.saveAndNotifyListeners();
  }

  set videoPreview(final int? o) {
    this._settingData.videoPreview = o;
    this.saveAndNotifyListeners();
  }

  set imagePreview(final int? o) {
    this._settingData.imagePreview = o;
    this.saveAndNotifyListeners();
  }

  /// image compress
  set imgCompress(final int o) {
    this._settingData.imgCompress = o;
    this.saveAndNotifyListeners();
  }

  /// theme style
  set themeStyle(final int o) {
    this._settingData.themeStyle = o;
    this.saveAndNotifyListeners();
  }

  /// theme color
  set themeColor(final int? o) {
    this._settingData.themeColor = o;
    this.saveAndNotifyListeners();
  }

  /// fontFamily
  set fontFamily(final String? fontFamily) {
    this._settingData.fontFamily = fontFamily;
    this.saveAndNotifyListeners();
  }

  set openTranslate(final int? o) {
    this._settingData.openTranslate = o;
    this.saveAndNotifyListeners();
  }

  set translateSourceArgs(final String? o) {
    this._settingData.translateSourceArgs = o;
    this.saveAndNotifyListeners();
  }

  set translateTarget(final String? o) {
    this._settingData.translateTarget = o;
    this.saveAndNotifyListeners();
  }

  set broadcaseWhenBoost(final int? o) {
    this._settingData.broadcaseWhenBoost = o;
    this.saveAndNotifyListeners();
  }

  set fontSize(final double o) {
    this._settingData.fontSize = o;
    this.saveAndNotifyListeners();
  }

  set webviewAppbarOpen(final int o) {
    this._settingData.webviewAppbarOpen = o;
    this.saveAndNotifyListeners();
  }

  set tableMode(final int? o) {
    this._settingData.tableMode = o;
    this.saveAndNotifyListeners();
  }

  set autoOpenSensitive(final int? o) {
    this._settingData.autoOpenSensitive = o;
    this.saveAndNotifyListeners();
  }

  set relayMode(final int? o) {
    this._settingData.relayMode = o;
    this.saveAndNotifyListeners();
  }

  set eventSignCheck(final int? o) {
    this._settingData.eventSignCheck = o;
    this.saveAndNotifyListeners();
  }

  set limitNoteHeight(final int? o) {
    this._settingData.limitNoteHeight = o;
    this.saveAndNotifyListeners();
  }

  Future<void> saveAndNotifyListeners({final bool updateUI = true}) async {
    this._settingData.updatedTime = DateTime.now().millisecondsSinceEpoch;
    final m = _settingData.toJson();
    final jsonStr = json.encode(m);
    await sharedPreferences.setString(DataKey.SETTING, jsonStr);
    this._reloadTranslateSourceArgs();

    if (updateUI) {
      this.notifyListeners();
    }
  }
}

class SettingData {
  SettingData({
    this.lockOpen = OpenStatus.CLOSE,
    this.defaultIndex,
    this.defaultTab,
    this.linkPreview,
    this.videoPreviewInList,
    this.network,
    this.imageService,
    this.videoPreview,
    this.imagePreview,
    this.imgCompress = 50,
    this.themeStyle = ThemeStyle.AUTO,
    this.themeColor,
    this.fontFamily,
    this.openTranslate,
    this.translateTarget,
    this.translateSourceArgs,
    this.broadcaseWhenBoost,
    this.fontSize,
    this.webviewAppbarOpen = OpenStatus.OPEN,
    this.tableMode,
    this.autoOpenSensitive,
    this.relayMode,
    this.eventSignCheck,
    this.limitNoteHeight,
    this.updatedTime = 0,
  });

  SettingData.fromJson(final Map<String, dynamic> json) {
    if (json["lockOpen"] != null) {
      this.lockOpen = json["lockOpen"];
    } else {
      this.lockOpen = OpenStatus.CLOSE;
    }
    this.defaultIndex = json["defaultIndex"];
    this.defaultTab = json["defaultTab"];
    this.linkPreview = json["linkPreview"];
    this.videoPreviewInList = json["videoPreviewInList"];
    this.network = json["network"];
    this.imageService = json["imageService"];
    this.videoPreview = json["videoPreview"];
    this.imagePreview = json["imagePreview"];
    if (json["imgCompress"] != null) {
      this.imgCompress = json["imgCompress"];
    } else {
      this.imgCompress = 50;
    }
    if (json["themeStyle"] != null) {
      this.themeStyle = json["themeStyle"];
    } else {
      this.themeStyle = ThemeStyle.AUTO;
    }
    this.themeColor = json["themeColor"];
    this.openTranslate = json["openTranslate"];
    this.translateTarget = json["translateTarget"];
    this.translateSourceArgs = json["translateSourceArgs"];
    this.broadcaseWhenBoost = json["broadcaseWhenBoost"];
    this.fontSize = json["fontSize"];
    this.webviewAppbarOpen = json["webviewAppbarOpen"] ?? OpenStatus.OPEN;
    this.tableMode = json["tableMode"];
    this.autoOpenSensitive = json["autoOpenSensitive"];
    this.relayMode = json["relayMode"];
    this.eventSignCheck = json["eventSignCheck"];
    this.limitNoteHeight = json["limitNoteHeight"];
    if (json["updatedTime"] != null) {
      this.updatedTime = json["updatedTime"];
    } else {
      this.updatedTime = 0;
    }
  }

  @override
  String toString() {
    return jsonEncode(this.toJson());
  }

  /// open lock
  late int lockOpen;

  int? defaultIndex;
  int? defaultTab;
  int? linkPreview;
  int? videoPreviewInList;

  String? network;
  String? imageService;

  int? videoPreview;
  int? imagePreview;

  /// image compress
  late int imgCompress;

  /// theme style
  late int themeStyle;

  /// theme color
  int? themeColor;

  /// fontFamily
  String? fontFamily;

  int? openTranslate;
  String? translateTarget;
  String? translateSourceArgs;
  int? broadcaseWhenBoost;
  double? fontSize;

  late int webviewAppbarOpen;

  int? tableMode;
  int? autoOpenSensitive;
  int? relayMode;
  int? eventSignCheck;
  int? limitNoteHeight;

  /// updated time
  late int updatedTime;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["lockOpen"] = this.lockOpen;
    data["defaultIndex"] = this.defaultIndex;
    data["defaultTab"] = this.defaultTab;
    data["linkPreview"] = this.linkPreview;
    data["videoPreviewInList"] = this.videoPreviewInList;
    data["network"] = this.network;
    data["imageService"] = this.imageService;
    data["videoPreview"] = this.videoPreview;
    data["imagePreview"] = this.imagePreview;
    data["imgCompress"] = this.imgCompress;
    data["themeStyle"] = this.themeStyle;
    data["themeColor"] = this.themeColor;
    data["fontFamily"] = this.fontFamily;
    data["openTranslate"] = this.openTranslate;
    data["translateTarget"] = this.translateTarget;
    data["translateSourceArgs"] = this.translateSourceArgs;
    data["broadcaseWhenBoost"] = this.broadcaseWhenBoost;
    data["fontSize"] = this.fontSize;
    data["webviewAppbarOpen"] = this.webviewAppbarOpen;
    data["tableMode"] = this.tableMode;
    data["autoOpenSensitive"] = this.autoOpenSensitive;
    data["relayMode"] = this.relayMode;
    data["eventSignCheck"] = this.eventSignCheck;
    data["limitNoteHeight"] = this.limitNoteHeight;
    data["updatedTime"] = this.updatedTime;
    return data;
  }
}

class CustomSecureStorage {
  CustomSecureStorage()
      : this.fss = FlutterSecureStorage(aOptions: _getAndroidOptions());

  final FlutterSecureStorage fss;

  static AndroidOptions _getAndroidOptions() {
    return const AndroidOptions(
      encryptedSharedPreferences: true,
    );
  }

  Future<String?> read(String key) async {
    if (!PlatformUtil.isWindowsOrLinux()) {
      return await this.fss.read(key: key, aOptions: _getAndroidOptions());
    } else {
      final value = sharedPreferences.get("secret:$key");
      return value == null ? null : value as String;
    }
  }

  Future<void> write(String key, String value) async {
    if (!PlatformUtil.isWindowsOrLinux()) {
      await this
          .fss
          .write(key: key, value: value, aOptions: _getAndroidOptions());
    } else {
      sharedPreferences.setString("secret:$key", value);
      return;
    }
  }
}
