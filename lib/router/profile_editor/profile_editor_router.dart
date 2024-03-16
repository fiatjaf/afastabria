import "package:flutter/material.dart";
import "package:loure/client/upload/uploader.dart";
import "package:loure/data/metadata.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/router_util.dart";

import "package:loure/component/appbar4stack.dart";
import "package:loure/consts/base.dart";
import "package:loure/main.dart";

class ProfileEditorRouter extends StatefulWidget {
  const ProfileEditorRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return ProfileEditorRouterState();
  }
}

class ProfileEditorRouterState extends State<ProfileEditorRouter> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  TextEditingController pictureController = TextEditingController();
  TextEditingController bannerController = TextEditingController();
  TextEditingController websiteController = TextEditingController();
  TextEditingController nip05Controller = TextEditingController();
  TextEditingController lud16Controller = TextEditingController();
  TextEditingController lud06Controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    metadataLoader.load(nostr.publicKey).then((final metadata) {
      this.displayNameController.text = metadata.displayName ?? "";
      this.nameController.text = metadata.name ?? "";
      this.aboutController.text = metadata.about ?? "";
      this.pictureController.text = metadata.picture ?? "";
      this.bannerController.text = metadata.banner ?? "";
      this.websiteController.text = metadata.website ?? "";
      this.nip05Controller.text = metadata.nip05 ?? "";
      this.lud16Controller.text = metadata.lud16 ?? "";
      this.lud06Controller.text = metadata.lud06 ?? "";
    });
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;
    // var mainColor = themeData.primaryColor;
    final textColor = themeData.textTheme.bodyMedium!.color;

    final submitBtn = TextButton(
      onPressed: profileSave,
      style: const ButtonStyle(),
      child: Text(
        "Submit",
        style: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
      ),
    );

    Color? appbarBackgroundColor = Colors.transparent;
    final appBar = Appbar4Stack(
      backgroundColor: appbarBackgroundColor,
      // title: appbarTitle,
      action: Container(
        margin: const EdgeInsets.only(right: Base.BASE_PADDING),
        child: submitBtn,
      ),
    );

    const margin = EdgeInsets.only(bottom: Base.BASE_PADDING);
    const padding = EdgeInsets.only(left: 20, right: 20);

    List<Widget> list = [];

    if (PlatformUtil.isTableMode()) {
      list.add(Container(
        height: 30,
      ));
    }

    list.add(Container(
      margin: margin,
      padding: padding,
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: this.displayNameController,
            decoration: const InputDecoration(labelText: "Display Name"),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
          ),
          child: const Text(" @ "),
        ),
        Expanded(
          child: TextField(
            controller: this.nameController,
            decoration: const InputDecoration(labelText: "Name"),
          ),
        ),
      ]),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        minLines: 2,
        maxLines: 10,
        controller: this.aboutController,
        decoration: const InputDecoration(labelText: "About"),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: this.pictureController,
        decoration: InputDecoration(
          prefixIcon: GestureDetector(
            onTap: pickPicture,
            child: const Icon(Icons.image),
          ),
          labelText: "Picture",
        ),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: this.bannerController,
        decoration: InputDecoration(
          prefixIcon: GestureDetector(
            onTap: pickBanner,
            child: const Icon(Icons.image),
          ),
          labelText: "Banner",
        ),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: this.websiteController,
        decoration: const InputDecoration(labelText: "Website"),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: this.nip05Controller,
        decoration: const InputDecoration(labelText: "Nip05"),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: this.lud16Controller,
        decoration: const InputDecoration(
            labelText: "Lud16", hintText: "walletname@walletservice.com"),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: this.lud06Controller,
        decoration: const InputDecoration(labelText: "Lnurl"),
      ),
    ));

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: mediaDataCache.size.width,
            height: mediaDataCache.size.height - mediaDataCache.padding.top,
            margin: EdgeInsets.only(top: mediaDataCache.padding.top),
            child: Container(
              color: cardColor,
              padding: EdgeInsets.only(
                  top: mediaDataCache.padding.top + Base.BASE_PADDING),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: list,
                ),
              ),
            ),
          ),
          Positioned(
            top: mediaDataCache.padding.top,
            left: 0,
            right: 0,
            child: Container(
              child: appBar,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickPicture() async {
    final filepath = await pickImageAndUpload();
    if (filepath != null && filepath != "") {
      this.pictureController.text = filepath;
    }
  }

  Future<void> pickBanner() async {
    final filepath = await pickImageAndUpload();
    if (filepath != null && filepath != "") {
      this.bannerController.text = filepath;
    }
  }

  Future<String?> pickImageAndUpload() async {
    if (PlatformUtil.isWeb()) {
      return null;
    }

    final filepath = await Uploader.pick(context);
    if (filepath != null && filepath != "") {
      return await Uploader.upload(
        filepath,
        imageService: settingProvider.imageService,
      );
    }
    return null;
  }

  void profileSave() {
    String? filledOrNull(String s) {
      s = s.trim();
      if (s != "") return s;
      return null;
    }

    final metadata = Metadata(
      null,
      pubkey: nostr.publicKey,
      name: filledOrNull(nameController.text),
      displayName: filledOrNull(displayNameController.text),
      about: filledOrNull(aboutController.text),
      picture: filledOrNull(pictureController.text),
      banner: filledOrNull(bannerController.text),
      website: filledOrNull(websiteController.text),
      nip05: filledOrNull(nip05Controller.text),
      lud16: filledOrNull(lud16Controller.text),
      lud06: filledOrNull(lud06Controller.text),
    );

    nostr.sendMetadata(metadata);
    RouterUtil.back(context);
  }
}
