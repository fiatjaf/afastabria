import "dart:convert";

import "package:loure/client/input.dart";
import "package:auto_size_text_field/auto_size_text_field.dart";
import "package:bot_toast/bot_toast.dart";
import "package:emoji_picker_flutter/emoji_picker_flutter.dart";
import "package:flutter/material.dart";
import "package:flutter_quill/flutter_quill.dart" as quill;
import "package:google_fonts/google_fonts.dart";
import "package:image_picker/image_picker.dart";
import "package:provider/provider.dart";

import "package:loure/component/datetime_picker_component.dart";
import "package:loure/component/webview_router.dart";
import "package:loure/provider/list_provider.dart";
import "package:loure/sendbox/sendbox.dart";
import "package:loure/client/event.dart";
import "package:loure/client/event_kind.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/client/upload/uploader.dart";
import "package:loure/consts/base.dart";
import "package:loure/data/custom_emoji.dart";
import "package:loure/main.dart";
import "package:loure/router/index/index_app_bar.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/string_util.dart";
import "package:loure/component/content/content_decoder.dart";
import "package:loure/component/image_component.dart";
import "package:loure/component/editor/cust_embed_types.dart";
import "package:loure/component/editor/custom_emoji_add_dialog.dart";
import "package:loure/component/editor/search_mention_event_component.dart";
import "package:loure/component/editor/search_mention_user_component.dart";
import "package:loure/component/editor/text_input_and_search_dialog.dart";
import "package:loure/component/editor/text_input_dialog.dart";

mixin EditorMixin {
  quill.QuillController editorController = quill.QuillController.basic();

  var focusNode = FocusNode();
  bool inputPoll = false;

  String? getPubkey();
  BuildContext getContext();
  void updateUI();
  List<List<String>> getTags();
  List<List<String>> getTagsAddedWhenSend();

  void handleFocusInit() {
    focusNode.addListener(() {
      if (focusNode.hasFocus && (emojiShow || customEmojiShow)) {
        emojiShow = false;
        customEmojiShow = false;
        updateUI();
      }
    });
  }

  Widget buildEditorBtns({
    final bool showShadow = true,
    final double? height = IndexAppBar.height,
  }) {
    final themeData = Theme.of(getContext());
    final scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    // var hintColor = themeData.hintColor;
    final mainColor = themeData.primaryColor;

    List<Widget> inputBtnList = [];
    if (!PlatformUtil.isWeb()) {
      inputBtnList.add(quill.QuillToolbarIconButton(
        onPressed: pickImage,
        icon: const Icon(Icons.image),
        isSelected: false,
        iconTheme: null,
      ));
    }
    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      inputBtnList.add(quill.QuillToolbarIconButton(
        onPressed: takeAPhoto,
        icon: const Icon(Icons.camera),
        isSelected: false,
        iconTheme: null,
      ));
      inputBtnList.add(quill.QuillToolbarIconButton(
        onPressed: tackAVideo,
        icon: const Icon(Icons.video_call),
        isSelected: false,
        iconTheme: null,
      ));
    }
    inputBtnList.addAll([
      quill.QuillToolbarIconButton(
        onPressed: customEmojiSelect,
        icon: const Icon(Icons.add_reaction_outlined),
        isSelected: false,
        iconTheme: null,
      ),
      quill.QuillToolbarIconButton(
        onPressed: emojiBeginToSelect,
        icon: const Icon(Icons.tag_faces),
        isSelected: false,
        iconTheme: null,
      ),
      quill.QuillToolbarIconButton(
        onPressed: _inputMentionUser,
        icon: const Icon(Icons.alternate_email_sharp),
        isSelected: false,
        iconTheme: null,
      ),
      quill.QuillToolbarIconButton(
        onPressed: _inputMentionEvent,
        icon: const Icon(Icons.format_quote),
        isSelected: false,
        iconTheme: null,
      ),
      quill.QuillToolbarIconButton(
        onPressed: _inputTag,
        icon: const Icon(Icons.tag),
        isSelected: false,
        iconTheme: null,
      ),
      quill.QuillToolbarIconButton(
        onPressed: _addWarning,
        icon: Icon(Icons.warning, color: showWarning ? Colors.red : null),
        isSelected: false,
        iconTheme: null,
      ),
      quill.QuillToolbarIconButton(
        onPressed: _addTitle,
        icon: Icon(Icons.title, color: showTitle ? mainColor : null),
        isSelected: false,
        iconTheme: null,
      ),
      quill.QuillToolbarIconButton(
        onPressed: selectedTime,
        icon: Icon(Icons.timer_outlined,
            color: publishAt != null ? mainColor : null),
        isSelected: false,
        iconTheme: null,
      )
    ]);

    inputBtnList.add(
      Container(
        width: Base.BASE_PADDING,
      ),
    );

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scaffoldBackgroundColor,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, -5),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: inputBtnList,
        ),
      ),
    );
  }

  Widget buildEmojiSelector() {
    final themeData = Theme.of(getContext());
    final mainColor = themeData.primaryColor;
    final bgColor = themeData.scaffoldBackgroundColor;

    return SizedBox(
      height: 260,
      child: EmojiPicker(
        onEmojiSelected: (final Category? category, final Emoji emoji) {
          emojiInsert(emoji);
        },
        onBackspacePressed: null,
        // textEditingController:
        //     textEditionController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
        config: Config(
          columns: 10,
          emojiSizeMax: 20 * (PlatformUtil.isIOS() ? 1.30 : 1.0),
          verticalSpacing: 0,
          horizontalSpacing: 0,
          gridPadding: EdgeInsets.zero,
          initCategory: Category.RECENT,
          bgColor: bgColor,
          indicatorColor: mainColor,
          iconColor: Colors.grey,
          iconColorSelected: mainColor,
          backspaceColor: mainColor,
          skinToneDialogBgColor: Colors.white,
          skinToneIndicatorColor: Colors.grey,
          enableSkinTones: true,
          // showRecentsTab: true,
          recentTabBehavior: RecentTabBehavior.RECENT,
          recentsLimit: 30,
          emojiTextStyle:
              PlatformUtil.isWeb() ? GoogleFonts.notoColorEmoji() : null,
          noRecents: const Text(
            "No Recents",
            style: TextStyle(fontSize: 14, color: Colors.black26),
            textAlign: TextAlign.center,
          ), // Needs to be const Widget
          loadingIndicator: const SizedBox.shrink(), // Needs to be const Widget
          tabIndicatorAnimDuration: kTabScrollDuration,
          categoryIcons: const CategoryIcons(),
          buttonMode: ButtonMode.MATERIAL,
        ),
      ),
    );
  }

  bool emojiShow = false;

  void emojiBeginToSelect() {
    FocusScope.of(getContext()).unfocus();
    emojiShow = true;
    customEmojiShow = false;
    updateUI();
  }

  void emojiInsert(final Emoji emoji) {
    final index = editorController.selection.baseOffset;
    final length = editorController.selection.extentOffset - index;
    editorController.replaceText(
        index, length, emoji.emoji, TextSelection.collapsed(offset: index + 2),
        ignoreFocus: true);
    updateUI();
  }

  Future<void> pickImage() async {
    final filepath = await Uploader.pick(getContext());
    _imageSubmitted(filepath);
  }

  void _imageSubmitted(final String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      final fileType = ContentDecoder.getPathType(value);
      if (fileType == "image") {
        editorController.replaceText(
            index, length, quill.BlockEmbed.image(value), null);

        editorController.moveCursorToPosition(index + 1);
      } else if (fileType == "video") {
        editorController.replaceText(
            index, length, quill.BlockEmbed.video(value), null);

        editorController.moveCursorToPosition(index + 1);
      }
    }
  }

  Future<void> takeAPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _imageSubmitted(photo.path);
    }
  }

  Future<void> tackAVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickVideo(source: ImageSource.camera);
    if (photo != null) {
      _imageSubmitted(photo.path);
    }
  }

  Future<void> _inputMentionEvent() async {
    final context = getContext();
    var value = await TextInputAndSearchDialog.show(
      context,
      "Search",
      "Please input event id",
      const SearchMentionEventComponent(),
      hintText: "Note Id",
    );
    if (StringUtil.isNotBlank(value)) {
      // check nip19 value
      if (NIP19.isNoteId(value!)) {
        value = NIP19.decode(value);
      }
      _submitMentionEvent(value);
    }
  }

  void _submitMentionEvent(final String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.mention_event, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputMentionUser() async {
    final context = getContext();
    var value = await TextInputAndSearchDialog.show(
      context,
      "Search",
      "Please input user pubkey",
      const SearchMentionUserComponent(),
      hintText: "User Pubkey",
    );
    if (StringUtil.isNotBlank(value)) {
      // check nip19 value
      if (NIP19.isPubkey(value!)) {
        value = NIP19.decode(value);
      }
      _submitMentionUser(value);
    }
  }

  void _submitMentionUser(final String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.mention_user, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputTag() async {
    final context = getContext();
    final value = await TextInputDialog.show(context, "Please_input_Topic_text",
        valueCheck: baseInputCheck, hintText: "Topic");
    if (StringUtil.isNotBlank(value)) {
      _submitTag(value);
    }
  }

  bool baseInputCheck(final BuildContext context, final String value) {
    if (value.contains(" ")) {
      BotToast.showText(text: "Text can't contain blank space");
      return false;
    }
    if (value.contains("\n")) {
      BotToast.showText(text: "Text can't contain newline");
      return false;
    }
    return true;
  }

  void _submitTag(final String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.tag, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<Event?> doDocumentSave() async {
    // customEmoji map
    Map<String, int> customEmojiMap = {};
    final tags = [...getTags()];
    final tagsAddedWhenSend = [...getTagsAddedWhenSend()];

    final delta = editorController.document.toDelta();
    final operations = delta.toList();
    String result = "";
    for (final operation in operations) {
      if (operation.key == "insert") {
        if (operation.data is Map) {
          final m = operation.data as Map;
          var value = m["image"];
          if (StringUtil.isBlank(value)) {
            value = m["video"];
          }
          if (StringUtil.isNotBlank(value) && value is String) {
            if (value.indexOf("http") != 0) {
              // this is a local image, update it first
              final imagePath = await Uploader.upload(
                value,
                imageService: settingProvider.imageService,
              );
              if (StringUtil.isNotBlank(imagePath)) {
                value = imagePath;
              } else {
                BotToast.showText(text: "Upload_fail");
                return null;
              }
            }
            result = handleBlockValue(result, value);
            continue;
          }

          value = m["tag"];
          if (StringUtil.isNotBlank(value)) {
            result = handleInlineValue(result, "#$value");
            tags.add(["t", value]);
            continue;
          }

          value = m["mentionUser"];
          if (StringUtil.isNotBlank(value)) {
            if (!_lastIsSpace(result) && !_lastIsLineEnd(result)) {
              result += " ";
            }
            // if (agreement == null) {
            // tags.add(["p", value]);
            //   var index = tags.length - 1;
            //   result += "#[$index] ";
            // } else {
            result += "nostr:${NIP19.encodePubKey(value)} ";
            // }
            continue;
          }

          value = m["mentionEvent"];
          if (StringUtil.isNotBlank(value)) {
            if (!_lastIsLineEnd(result)) {
              result += " ";
            }

            String? author;
            List<String> relays = [];
            final mentionEvent = nostr.idIndex[value];
            if (mentionEvent != null) {
              author = mentionEvent.pubkey;
              relays = mentionEvent.sources.take(3).toList();
            }
            result +=
                "${NIP19.encodeNevent(EventPointer(value, relays, author: author))} ";
            continue;
          }

          value = m["customEmoji"];
          if (value != null && value is CustomEmoji) {
            result += ":${value.name}: ";

            if (customEmojiMap[value.name] == null) {
              customEmojiMap[value.name] = 1;
              tags.add(["emoji", value.name, value.filepath]);
            }
            continue;
          }
        } else {
          result += operation.data.toString();
        }
      }
    }
    result = result.trim();
    // log(result);
    // print(tags);
    // print(tagsAddWhenSend);

    List<List<String>> allTags = [];
    allTags.addAll(tags);
    allTags.addAll(tagsAddedWhenSend);

    final subject = subjectController.text;
    if (StringUtil.isNotBlank(subject)) {
      allTags.add(["subject", subject]);
    }

    if (showWarning) {
      allTags.add(["content-warning", ""]);
    }

    // text note
    final event = Event.finalize(
        nostr.privateKey, EventKind.TEXT_NOTE, allTags, result,
        publishAt: publishAt);

    if (publishAt != null) {
      await SendBox.submit(event, nostr.relayList.write);
    } else {
      pool.publish(nostr.relayList.write, event);
      print(jsonEncode(event.toJson()));
    }

    return event;
  }

  String handleInlineValue(String result, final String value) {
    if (!_lastIsSpace(result) && !_lastIsLineEnd(result)) {
      result += " ";
    }
    result += "$value ";
    return result;
  }

  String handleBlockValue(String result, final String value) {
    if (!_lastIsLineEnd(result)) {
      result += "\n";
    }
    result += "$value\n";
    return result;
  }

  bool _lastIsSpace(final String str) {
    if (StringUtil.isBlank(str)) {
      return true;
    }

    final length = str.length;
    if (str[length - 1] == " ") {
      return true;
    }
    return false;
  }

  bool _lastIsLineEnd(final String str) {
    if (StringUtil.isBlank(str)) {
      return true;
    }

    final length = str.length;
    if (str[length - 1] == "\n") {
      return true;
    }
    return false;
  }

  bool customEmojiShow = false;

  void customEmojiSelect() {
    FocusScope.of(getContext()).unfocus();
    customEmojiShow = true;
    emojiShow = false;
    updateUI();
  }

  Future<void> addCustomEmoji() async {
    final emoji = await CustomEmojiAddDialog.show(getContext());
    if (emoji != null) {
      emojiProvider.addCustomEmoji(emoji);
    }
  }

  void addEmojiToEditor(final CustomEmoji emoji) {
    final index = editorController.selection.baseOffset;
    final length = editorController.selection.extentOffset - index;

    editorController.replaceText(
        index,
        length,
        quill.Embeddable(CustEmbedTypes.custom_emoji, emoji),
        TextSelection.collapsed(offset: index + 2),
        ignoreFocus: true);
    updateUI();
  }

  double emojiBtnWidth = 60;

  Widget buildEmojiListsWidget() {
    final context = getContext();
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    final labelUnSelectColor = themeData.dividerColor;

    return Container(
      height: 260,
      padding: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
      width: double.infinity,
      child: Selector<EmojiProvider, Event?>(
        builder: (final context, final emojiEvent, final child) {
          final emojiLists = emojiProvider.emojis(emojiEvent);

          List<Widget> tabBarList = [];
          List<Widget> tabBarViewList = [];

          final length = emojiLists.length;
          for (var index = 0; index < length; index++) {
            final emojiList = emojiLists[index];
            final isCustomEmoji = index == 0;

            tabBarList.add(Text(
              emojiList.key,
              overflow: TextOverflow.ellipsis,
            ));
            tabBarViewList.add(buildEmojiListWidget(
              emojiList.value,
              isCustomEmoji: isCustomEmoji,
            ));
          }

          final findMoreBtn = GestureDetector(
            onTap: () {
              WebViewRouter.open(context, "https://emojis-iota.vercel.app/");
            },
            child: const SizedBox(
              width: 40,
              child: Icon(Icons.search),
            ),
          );

          return DefaultTabController(
            length: tabBarList.length,
            child: Column(
              children: [
                SizedBox(
                  height: Base.TABBAR_HEIGHT,
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: Base.TABBAR_HEIGHT,
                          child: TabBar(
                            tabs: tabBarList,
                            indicatorColor: mainColor,
                            labelColor: mainColor,
                            unselectedLabelColor: labelUnSelectColor,
                            isScrollable: true,
                          ),
                        ),
                      ),
                      findMoreBtn,
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(children: tabBarViewList),
                ),
              ],
            ),
          );
        },
        selector: (final context, final provider) {
          return provider.getEmojiEvent();
        },
      ),
    );
  }

  Widget buildEmojiListWidget(final List<CustomEmoji> emojis,
      {final bool isCustomEmoji = false}) {
    List<Widget> list = [];

    if (isCustomEmoji) {
      list.add(GestureDetector(
        onTap: addCustomEmoji,
        child: SizedBox(
          width: emojiBtnWidth,
          height: emojiBtnWidth,
          child: const Icon(
            Icons.add,
            size: 50,
          ),
        ),
      ));
    }

    for (final emoji in emojis) {
      list.add(GestureDetector(
        onTap: () {
          addEmojiToEditor(emoji);
        },
        child: Container(
          // constraints:
          //     BoxConstraints(maxWidth: emojiBtnWidth, maxHeight: emojiBtnWidth),
          width: emojiBtnWidth,
          height: emojiBtnWidth,
          alignment: Alignment.center,
          child: ImageComponent(
            imageUrl: emoji.filepath,
            placeholder: (final context, final url) => Container(),
          ),
        ),
      ));
    }

    final main = SingleChildScrollView(
      child: Wrap(
        // runAlignment: WrapAlignment.center,
        runSpacing: Base.BASE_PADDING_HALF,
        spacing: Base.BASE_PADDING_HALF,
        // runAlignment: WrapAlignment.center,
        children: list,
      ),
    );

    return Container(
      height: 260,
      padding: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
      width: double.infinity,
      child: main,
    );
  }

  bool showWarning = false;

  void _addWarning() {
    showWarning = !showWarning;
    updateUI();
  }

  bool showTitle = false;

  TextEditingController subjectController = TextEditingController();

  void _addTitle() {
    subjectController.clear();
    showTitle = !showTitle;
    updateUI();
  }

  Widget buildTitleWidget() {
    final themeData = Theme.of(getContext());
    final fontSize = themeData.textTheme.bodyLarge!.fontSize;
    final hintColor = themeData.hintColor;

    return Container(
      // color: Colors.red,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: AutoSizeTextField(
        maxLength: 80,
        controller: subjectController,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: "Please input title",
          border: InputBorder.none,
          hintStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            color: hintColor.withOpacity(0.8),
          ),
          counterText: "",
        ),
      ),
    );
  }

  DateTime? publishAt;

  Future<void> selectedTime() async {
    final dt = await DatetimePickerComponent.show(getContext(),
        dateTime: publishAt ?? DateTime.now());
    publishAt = dt;
    updateUI();
  }
}
