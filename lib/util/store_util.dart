import "dart:io";
import "dart:typed_data";

import "package:image_gallery_saver/image_gallery_saver.dart";
import "package:path_provider/path_provider.dart";

import "package:loure/util/string_util.dart";

class StoreUtil {
  static Future<String> getBasePath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir.path;
  }

  static Future<String> saveBS2TempFile(
      final String extension, final List<int> uint8list,
      {final String? randFolderName, final String? filename}) async {
    final tempDir = await getTemporaryDirectory();
    var folderPath = tempDir.path;
    if (StringUtil.isNotBlank(randFolderName)) {
      folderPath = "$folderPath/${randFolderName!}";
      checkAndCreateDir("$folderPath/");
    }
    var tempFilePath = "$folderPath/temp.$extension";
    if (StringUtil.isNotBlank(filename)) {
      tempFilePath = "$folderPath/${filename!}.$extension";
    }

    final tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(uint8list);

    return tempFilePath;
  }

  static Future<void> save2File(
      final String filepath, final List<int> uint8list) async {
    final tempFile = File(filepath);
    await tempFile.writeAsBytes(uint8list);
  }

  static String bytesToShowStr(final int bytesLength) {
    double bl = bytesLength.toDouble();
    if (bl < 1024) {
      return "$bl B";
    }

    bl = bl / 1024;
    if (bl < 1024) {
      return "${bl.toStringAsFixed(2)} KB";
    }

    bl = bl / 1024;
    if (bl < 1024) {
      return "${bl.toStringAsFixed(2)} MB";
    }

    bl = bl / 1024;
    if (bl < 1024) {
      return "${bl.toStringAsFixed(2)} GB";
    }

    return "";
  }

  static void checkAndCreateDir(final String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync();
    }
  }

  static bool checkDir(final String dirPath) {
    final dir = Directory(dirPath);
    return dir.existsSync();
  }

  static String? getfileType(final String path) {
    final index = path.lastIndexOf(".");
    if (index == -1) {
      return null;
    }

    var n = path.substring(index);
    n = n.toLowerCase();

    final strs = n.split("?");
    final s = strs[0];

    if (s == ".png" ||
        s == ".jpg" ||
        s == ".jpeg" ||
        s == ".gif" ||
        s == ".webp") {
      return "image";
    } else if (s == ".mp4" || s == ".mov" || s == ".wmv") {
      return "video";
    } else {
      return null;
    }
  }

  static Future saveBS2Gallery(
      final String extension, final Uint8List uint8list) async {
    final tempPath = await StoreUtil.saveBS2TempFile(extension, uint8list);
    return await ImageGallerySaver.saveFile(tempPath);
  }
}
