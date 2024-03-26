import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:bot_toast/bot_toast.dart";
import "package:pretty_qr_code/pretty_qr_code.dart";
import "package:share_plus/share_plus.dart";

import "package:loure/client/nip19/nip19.dart";
import "package:loure/component/name_component.dart";
import "package:loure/component/user/metadata_top_component.dart";
import "package:loure/data/metadata.dart";
import "package:loure/main.dart";
import "package:screenshot/screenshot.dart";
import "package:loure/consts/base.dart";
import "package:loure/util/router_util.dart";
import "package:loure/util/store_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/image_component.dart";

// ignore: must_be_immutable
class QrcodeDialog extends StatefulWidget {
  QrcodeDialog({required this.pubkey, super.key});
  String pubkey;

  static Future<String?> show(
      final BuildContext context, final String pubkey) async {
    return await showDialog<String>(
        context: context,
        builder: (final context) {
          return QrcodeDialog(
            pubkey: pubkey,
          );
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _QrcodeDialog();
  }
}

class _QrcodeDialog extends State<QrcodeDialog> {
  static const double IMAGE_WIDTH = 40;
  static const double QR_WIDTH = 200;

  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final Color cardColor = themeData.cardColor;
    final hintColor = themeData.hintColor;

    List<Widget> list = [];
    final nip19Pubkey = NIP19.encodePubKey(widget.pubkey);
    final Widget topWidget = FutureBuilder(
      future: metadataLoader.load(widget.pubkey),
      initialData: Metadata.blank(widget.pubkey),
      builder: (final context, final snapshot) {
        final metadata = snapshot.data;

        Widget? imageWidget;
        if (metadata != null && StringUtil.isNotBlank(metadata.picture)) {
          imageWidget = ImageComponent(
            imageUrl: metadata.picture!,
            width: IMAGE_WIDTH,
            height: IMAGE_WIDTH,
            fit: BoxFit.cover,
            placeholder: (final context, final url) =>
                const CircularProgressIndicator(),
          );
        }

        final Widget userImageWidget = Container(
          alignment: Alignment.center,
          height: IMAGE_WIDTH,
          width: IMAGE_WIDTH,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
            color: Colors.grey,
          ),
          child: imageWidget,
        );

        final Widget userNameWidget = NameComponent(
          pubkey: widget.pubkey,
          metadata: metadata,
        );

        return Container(
          width: QR_WIDTH,
          margin: const EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              userImageWidget,
              Container(
                margin: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                child: SizedBox(
                  width: QR_WIDTH - IMAGE_WIDTH - Base.BASE_PADDING_HALF,
                  child: userNameWidget,
                ),
              ),
            ],
          ),
        );
      },
    );
    list.add(topWidget);
    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
      ),
      child: PrettyQr(
        data: nip19Pubkey,
        size: QR_WIDTH,
        image: const AssetImage("assets/imgs/logo/logo512.png"),
      ),
    ));
    list.add(GestureDetector(
      onTap: () {
        _doCopy(nip19Pubkey);
      },
      child: Container(
        width: QR_WIDTH + Base.BASE_PADDING_HALF * 2,
        padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
        decoration: BoxDecoration(
          color: hintColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SelectableText(
          nip19Pubkey,
          onTap: () {
            _doCopy(nip19Pubkey);
          },
        ),
      ),
    ));

    final main = Stack(
      children: [
        Screenshot(
          controller: screenshotController,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: list,
            ),
          ),
        ),
        Positioned(
          right: Base.BASE_PADDING_HALF,
          top: Base.BASE_PADDING_HALF,
          child: MetadataIconBtn(
            iconData: Icons.share,
            onTap: onShareTap,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }

  void _doCopy(final String text) {
    Clipboard.setData(ClipboardData(text: text)).then((final _) {
      BotToast.showText(text: "key_has_been_copy");
    });
  }

  void onShareTap() {
    screenshotController.capture().then((final Uint8List? imageData) async {
      if (imageData != null) {
        final tempFile = await StoreUtil.saveBS2TempFile(
          "png",
          imageData,
        );
        Share.shareXFiles([XFile(tempFile)]);
      }
    }).catchError(print);
  }
}
