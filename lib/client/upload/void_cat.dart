import "dart:io";
import "dart:typed_data";

import "package:convert/convert.dart";
import "package:crypto/crypto.dart";
import "package:dio/dio.dart";

import "package:loure/client/upload/uploader.dart";
import "package:loure/util/string_util.dart";

import "package:loure/consts/base64.dart";
import "package:loure/client/upload/nostr_build_uploader.dart";

class VoidCatUploader {
  static const String UPLOAD_ACTION = "https://void.cat/upload?cli=true";

  static Future<String?> upload(final String filePath,
      {final String? fileName}) async {
    Uint8List? bytes;
    if (BASE64.check(filePath)) {
      bytes = BASE64.toData(filePath);
    } else {
      final tempFile = File(filePath);
      bytes = await tempFile.readAsBytes();
    }

    final digest = sha256.convert(bytes);
    final fileHex = hex.encode(digest.bytes);

    Map<String, dynamic> headers = {};
    headers["content-type"] = "application/octet-stream";
    headers["v-full-digest"] = fileHex;

    final fileType = Uploader.getFileType(filePath);
    headers["v-content-type"] = fileType;
    if (StringUtil.isNotBlank(fileName)) {
      headers["V-Filename"] = fileName;
    }

    final response = await NostrBuildUploader.dio.post<String>(
      UPLOAD_ACTION,
      data: Stream.fromIterable(bytes.map((final e) => [e])),
      options: Options(
        headers: headers,
      ),
    );
    final body = response.data;

    return body;
  }
}
