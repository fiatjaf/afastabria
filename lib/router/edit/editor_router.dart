import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:nostrmo/client/aid.dart';
import 'package:nostrmo/component/editor/lnbc_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_event_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_user_embed_builder.dart';
import 'package:nostrmo/component/editor/pic_embed_builder.dart';
import 'package:nostrmo/component/editor/tag_embed_builder.dart';
import 'package:nostrmo/component/editor/video_embed_builder.dart';
import 'package:nostrmo/component/editor/zap_goal_input_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:pointycastle/ecc/api.dart';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart' as kind;
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/editor/custom_emoji_embed_builder.dart';
import 'package:nostrmo/component/editor/editor_mixin.dart';
import 'package:nostrmo/component/editor/poll_input_component.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:nostrmo/router/edit/editor_notify_item_component.dart';

// ignore: must_be_immutable
class EditorRouter extends StatefulWidget {
  static double appbarHeight = 56;

  // dm arg
  ECDHBasicAgreement? agreement;

  // dm arg
  String? pubkey;
  List<List<String>> tags = [];
  List<List<String>> tagsAddedWhenSend = [];
  List<List<String>> tagPs = [];
  List<quill.BlockEmbed>? initEmbeds;

  EditorRouter({
    super.key,
    required this.tags,
    required this.tagsAddedWhenSend,
    required this.tagPs,
    this.agreement,
    this.pubkey,
    this.initEmbeds,
  });

  static Future<Event?> open(
    BuildContext context, {
    List<List<String>>? tags,
    List<List<String>>? tagsAddedWhenSend,
    List<List<String>>? tagPs,
    ECDHBasicAgreement? agreement,
    String? pubkey,
    List<quill.BlockEmbed>? initEmbeds,
  }) {
    tags ??= [];
    tagsAddedWhenSend ??= [];
    tagPs ??= [];

    var editor = EditorRouter(
      tags: tags,
      tagsAddedWhenSend: tagsAddedWhenSend,
      tagPs: tagPs,
      agreement: agreement,
      pubkey: pubkey,
      initEmbeds: initEmbeds,
    );

    return RouterUtil.push(context, MaterialPageRoute(builder: (context) {
      return editor;
    }));
    // return Navigator.push(context, MaterialPageRoute(builder: (context) {
    //   return editor;
    // }));
  }

  @override
  State<StatefulWidget> createState() {
    return _EditorRouter();
  }
}

class _EditorRouter extends CustState<EditorRouter> with EditorMixin {
  List<EditorNotifyItem>? notifyItems;

  List<EditorNotifyItem> editorNotifyItems = [];

  @override
  void initState() {
    super.initState();
    handleFocusInit();
  }

  @override
  Widget doBuild(BuildContext context) {
    if (notifyItems == null) {
      notifyItems = [];
      for (var tagP in widget.tagPs) {
        if (tagP.length > 1) {
          notifyItems!.add(EditorNotifyItem(pubkey: tagP[1]));
        }
      }
    }

    var themeData = Theme.of(context);
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    // var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var textColor = themeData.textTheme.bodyMedium!.color;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    if (widget.tags.isNotEmpty) {
      for (var tag in widget.tags) {
        if (tag.length > 1) {
          var tagName = tag[0];
          var tagValue = tag[1];

          if (tagName == "a") {
            // this note is add to community
            var aid = AId.fromString(tagValue);
            if (aid != null &&
                aid.kind == kind.EventKind.COMMUNITY_DEFINITION) {
              list.add(Container(
                padding: const EdgeInsets.only(
                  left: Base.BASE_PADDING,
                  right: Base.BASE_PADDING,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: Base.BASE_PADDING),
                      child: Icon(
                        Icons.groups,
                        size: largeTextSize,
                        color: hintColor,
                      ),
                    ),
                    Text(
                      aid.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ));
            }
          }
        }
      }
    }

    if ((notifyItems != null && notifyItems!.isNotEmpty) ||
        (editorNotifyItems.isNotEmpty)) {
      List<Widget> tagPsWidgets = [];
      tagPsWidgets.add(const Text("Notify:"));
      for (var item in notifyItems!) {
        tagPsWidgets.add(EditorNotifyItemComponent(item: item));
      }
      for (var editorNotifyItem in editorNotifyItems) {
        var exist = notifyItems!.any((element) {
          return element.pubkey == editorNotifyItem.pubkey;
        });
        if (!exist) {
          tagPsWidgets.add(EditorNotifyItemComponent(item: editorNotifyItem));
        }
      }
      list.add(Container(
        padding: const EdgeInsets.only(
            left: Base.BASE_PADDING, right: Base.BASE_PADDING),
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        width: double.maxFinite,
        child: Wrap(
          spacing: Base.BASE_PADDING_HALF,
          runSpacing: Base.BASE_PADDING_HALF,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: tagPsWidgets,
        ),
      ));
    }

    if (showTitle) {
      list.add(buildTitleWidget());
    }

    if (publishAt != null) {
      var dateFormate = DateFormat("yyyy-MM-dd HH:mm");

      list.add(GestureDetector(
        onTap: selectedTime,
        behavior: HitTestBehavior.translucent,
        child: Container(
          margin:
              const EdgeInsets.only(left: 10, bottom: Base.BASE_PADDING_HALF),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined),
              Container(
                margin: const EdgeInsets.only(left: 4),
                child: Text(
                  dateFormate.format(publishAt!),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    Widget quillWidget = quill.QuillEditor(
      configurations: quill.QuillEditorConfigurations(
        placeholder: "What's happening",
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
        controller: editorController,
      ),
      scrollController: ScrollController(),
      focusNode: focusNode,
    );
    List<Widget> editorList = [];
    var editorInputWidget = Container(
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: quillWidget,
    );
    editorList.add(editorInputWidget);
    if (inputPoll) {
      editorList.add(PollInputComponent(
        pollInputController: pollInputController,
      ));
    }
    if (inputZapGoal) {
      editorList.add(ZapGoalInputComponent(
        zapGoalInputController: zapGoalInputController,
      ));
    }

    list.add(Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // focus to eidtor input widget
          focusNode.requestFocus();
        },
        child: Container(
          constraints: BoxConstraints(
              maxHeight: mediaDataCache.size.height -
                  mediaDataCache.padding.top -
                  EditorRouter.appbarHeight -
                  IndexAppBar.height),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: editorList,
            ),
          ),
        ),
      ),
    ));

    list.add(buildEditorBtns());
    if (emojiShow) {
      list.add(buildEmojiSelector());
    }
    if (customEmojiShow) {
      list.add(buildEmojiListsWidget());
    }

    return Scaffold(
      appBar: AppBar(
        // title: Text("Note"),
        backgroundColor: scaffoldBackgroundColor,
        leading: TextButton(
          onPressed: () {
            RouterUtil.back(context);
          },
          style: const ButtonStyle(),
          child: Icon(
            Icons.arrow_back_ios,
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: documentSave,
            style: const ButtonStyle(),
            child: Text(
              "Send",
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: list,
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (widget.initEmbeds != null && widget.initEmbeds!.isNotEmpty) {
      {
        final index = editorController.selection.baseOffset;
        final length = editorController.selection.extentOffset - index;

        editorController.replaceText(index, length, "\n", null);

        editorController.moveCursorToPosition(index + 1);
      }

      for (var embed in widget.initEmbeds!) {
        final index = editorController.selection.baseOffset;
        final length = editorController.selection.extentOffset - index;

        editorController.replaceText(index, length, embed, null);

        editorController.moveCursorToPosition(index + 1);
      }

      editorController.moveCursorToPosition(0);
    }

    editorNotifyItems = [];
    editorController.addListener(() {
      bool updated = false;
      Map<String, int> mentionUserMap = {};

      var delta = editorController.document.toDelta();
      var operations = delta.toList();
      for (var operation in operations) {
        if (operation.key == "insert") {
          if (operation.data is Map) {
            var m = operation.data as Map;
            var value = m["mentionUser"];
            if (StringUtil.isNotBlank(value)) {
              mentionUserMap[value] = 1;
            }
          }
        }
      }

      List<EditorNotifyItem> needDeleds = [];
      for (var item in editorNotifyItems) {
        var exist = mentionUserMap.remove(item.pubkey);
        if (exist == null) {
          updated = true;
          needDeleds.add(item);
        }
      }
      editorNotifyItems.removeWhere((element) => needDeleds.contains(element));

      if (mentionUserMap.isNotEmpty) {
        var entries = mentionUserMap.entries;
        for (var entry in entries) {
          updated = true;
          editorNotifyItems.add(EditorNotifyItem(pubkey: entry.key));
        }
      }

      if (updated) {
        setState(() {});
      }
    });
  }

  Future<void> documentSave() async {
    var cancelFunc = BotToast.showLoading();
    try {
      var event = await doDocumentSave();
      if (event == null) {
        BotToast.showText(text: "Send_fail");
        return;
      }
      RouterUtil.back(context, event);
    } finally {
      cancelFunc.call();
    }
  }

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  void updateUI() {
    setState(() {});
  }

  @override
  ECDHBasicAgreement? getAgreement() {
    return widget.agreement;
  }

  @override
  String? getPubkey() {
    return widget.pubkey;
  }

  @override
  List<List<String>> getTags() {
    return widget.tags;
  }

  @override
  List<List<String>> getTagsAddedWhenSend() {
    if ((notifyItems == null || notifyItems!.isEmpty) &&
        editorNotifyItems.isEmpty) {
      return widget.tagsAddedWhenSend;
    }

    List<List<String>> list = [];
    list.addAll(widget.tagsAddedWhenSend);
    for (var item in notifyItems!) {
      if (item.selected) {
        list.add(["p", item.pubkey]);
      }
    }

    for (var editorNotifyItem in editorNotifyItems) {
      var exist = notifyItems!.any((element) {
        return element.pubkey == editorNotifyItem.pubkey;
      });
      if (!exist) {
        if (editorNotifyItem.selected) {
          list.add(["p", editorNotifyItem.pubkey]);
        }
      }
    }

    return list;
  }
}
