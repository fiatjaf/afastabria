import "package:google_mlkit_translation/google_mlkit_translation.dart";

class TranslateModelManager {
  static TranslateModelManager? _manager;

  static TranslateModelManager getInstance() {
    if (_manager == null) {
      _manager = TranslateModelManager();
      _manager!._init();
    }
    return _manager!;
  }

  OnDeviceTranslatorModelManager? modelManager;

  void _init() {
    modelManager = OnDeviceTranslatorModelManager();
  }

  Future<void> checkAndDownloadAllModel() async {
    for (final lan in TranslateLanguage.values) {
      final bcpCode = lan.bcpCode;
      if (!await modelManager!.isModelDownloaded(bcpCode)) {
        print("begin to download model $bcpCode");
        await modelManager!.downloadModel(bcpCode, isWifiRequired: false);
      } else {
        print("model $bcpCode had bean downloaded");
      }
    }
  }

  Future<void> checkAndDownloadTargetModel(final List<String> bcpCodes) async {
    for (final bcpCode in bcpCodes) {
      if (!await modelManager!.isModelDownloaded(bcpCode)) {
        print("begin to download model $bcpCode");
        await modelManager!.downloadModel(bcpCode, isWifiRequired: false);
      } else {
        print("model $bcpCode had bean downloaded");
      }
    }
  }
}
