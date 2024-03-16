import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:loure/client/nip04/dm_session.dart';
import 'package:loure/component/cust_state.dart';
import 'package:loure/component/editor/editor_mixin.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:loure/client/nip04/nip04.dart';
import 'package:loure/component/editor/custom_emoji_embed_builder.dart';
import 'package:loure/component/editor/lnbc_embed_builder.dart';
import 'package:loure/component/editor/mention_event_embed_builder.dart';
import 'package:loure/component/editor/mention_user_embed_builder.dart';
import 'package:loure/component/editor/pic_embed_builder.dart';
import 'package:loure/component/editor/tag_embed_builder.dart';
import 'package:loure/component/editor/video_embed_builder.dart';
import 'package:loure/component/name_component.dart';
import 'package:loure/consts/base.dart';
import 'package:loure/data/metadata.dart';
import 'package:loure/main.dart';
import 'package:loure/provider/dm_provider.dart';
import 'package:loure/util/router_util.dart';
import 'package:loure/router/dm/dm_detail_item_component.dart';

class DMDetailRouter extends StatefulWidget {
  const DMDetailRouter({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DMDetailRouter();
  }
}

class _DMDetailRouter extends CustState<DMDetailRouter> with EditorMixin {
  DMSessionDetail? detail;

  ECDHBasicAgreement? agreement;
  Future<Metadata>? metadataFuture;

  @override
  void initState() {
    super.initState();
    handleFocusInit();
    this.metadataFuture = metadataLoader.load(detail!.dmSession.pubkey);
  }

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var textColor = themeData.textTheme.bodyMedium!.color;
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;

    // var hintColor = themeData.hintColor;

    var arg = RouterUtil.routerArgs(context);
    if (arg == null) {
      RouterUtil.back(context);
      return Container();
    }
    detail = arg as DMSessionDetail;

    var nameComponnet = FutureBuilder(
      future: this.metadataFuture,
      initialData: Metadata.blank(detail!.dmSession.pubkey),
      builder: (context, snapshot) {
        return NameComponnet(
          pubkey: detail!.dmSession.pubkey,
          metadata: snapshot.data,
        );
      },
    );

    var localPubkey = nostr.publicKey;
    agreement = NIP04.getAgreement(nostr.privateKey);

    List<Widget> list = [];

    var listWidget = Selector<DMProvider, DMSession?>(
      builder: (context, session, child) {
        if (session == null) {
          return Container();
        }

        return ListView.builder(
          itemBuilder: (context, index) {
            var event = session.get(index);
            if (event == null) {
              return null;
            }

            return DMDetailItemComponent(
              sessionPubkey: detail!.dmSession.pubkey,
              event: event,
              isLocal: localPubkey == event.pubKey,
              agreement: agreement!,
            );
          },
          reverse: true,
          itemCount: session.length(),
          dragStartBehavior: DragStartBehavior.down,
        );
      },
      selector: (context, provider) {
        return provider.getSession(detail!.dmSession.pubkey);
      },
    );

    list.add(Expanded(
      child: Container(
        margin: const EdgeInsets.only(
          bottom: Base.BASE_PADDING,
        ),
        child: listWidget,
      ),
    ));

    list.add(Container(
      decoration: BoxDecoration(
        color: scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, -5),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: quill.QuillEditor(
              configurations: quill.QuillEditorConfigurations(
                placeholder: "What's happening?",
                readOnly: false,
                embedBuilders: [
                  MentionUserEmbedBuilder(),
                  MentionEventEmbedBuilder(),
                  PicEmbedBuilder(),
                  VideoEmbedBuilder(),
                  LnbcEmbedBuilder(),
                  TagEmbedBuilder(),
                  CustomEmojiEmbedBuilder(),
                ],
                scrollable: true,
                autoFocus: false,
                expands: false,
                // padding: EdgeInsets.zero,
                padding: const EdgeInsets.only(
                  left: Base.BASE_PADDING,
                  right: Base.BASE_PADDING,
                ),
                maxHeight: 300, controller: editorController,
              ),
              scrollController: ScrollController(),
              focusNode: focusNode,
            ),
          ),
          TextButton(
            onPressed: send,
            style: const ButtonStyle(),
            child: Text(
              "Send",
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
    ));

    list.add(buildEditorBtns(showShadow: false, height: null));
    if (emojiShow) {
      list.add(buildEmojiSelector());
    }
    if (customEmojiShow) {
      list.add(buildEmojiListsWidget());
    }

    Widget main = SizedBox(
      width: double.maxFinite,
      height: double.maxFinite,
      child: Column(children: list),
    );

    if (detail!.info == null && detail!.dmSession.newestEvent != null) {
      main = SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Stack(
          children: [
            Positioned.fill(child: main),
            Positioned(
              child: GestureDetector(
                onTap: addDmSessionToKnown,
                child: Container(
                  margin: const EdgeInsets.all(Base.BASE_PADDING),
                  height: 30,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      "Add to known list",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
        title: nameComponnet,
      ),
      body: main,
    );
  }

  Future<void> send() async {
    var cancelFunc = BotToast.showLoading();
    try {
      var event = await doDocumentSave();
      if (event == null) {
        BotToast.showText(text: "Send_fail");
        return;
      }
      dmProvider.addEventAndUpdateReadedTime(detail!, event);
      editorController.clear();
      setState(() {});
    } finally {
      cancelFunc.call();
    }
  }

  Future<void> addDmSessionToKnown() async {
    var detail_ = await dmProvider.addDmSessionToKnown(detail!);
    setState(() {
      detail = detail_;
    });
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (detail != null &&
        detail!.info != null &&
        detail!.dmSession.newestEvent != null) {
      // detail!.info!.readedTime = detail!.dmSession.newestEvent!.createdAt;
      // DMSessionInfoDB.update(detail!.info!);
      dmProvider.updateReadedTime(detail);
    }
  }

  // Future<void> jumpToWriteMessage() async {
  //   var pubkey = detail!.dmSession.pubkey;
  //   List<List<String>> tags = [
  //     ["p", pubkey]
  //   ];
  //   var event = await EditorRouter.open(
  //     context,
  //     agreement: agreement,
  //     pubkey: pubkey,
  //     tags: tags,
  //     tagsAddedWhenSend: [],
  //   );
  //   if (event != null) {
  //     dmProvider.addEventAndUpdateReadedTime(detail!, event);
  //     setState(() {});
  //   }
  // }

  @override
  ECDHBasicAgreement? getAgreement() {
    return agreement;
  }

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  String? getPubkey() {
    return detail!.dmSession.pubkey;
  }

  @override
  List<List<String>> getTags() {
    var pubkey = detail!.dmSession.pubkey;
    List<List<String>> tags = [
      ["p", pubkey]
    ];
    return tags;
  }

  @override
  List<List<String>> getTagsAddedWhenSend() {
    return [];
  }

  @override
  void updateUI() {
    setState(() {});
  }
}
