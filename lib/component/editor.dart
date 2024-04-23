import "dart:convert";
import "dart:math";

import "package:fleather/fleather.dart";
import "package:flutter/material.dart";
import "package:loure/client/event.dart";
import "package:loure/client/nip19/nip19.dart";
import "package:loure/component/image_component.dart";
import "package:loure/data/db.dart";
import "package:parchment_delta/parchment_delta.dart";

import "package:loure/consts/base.dart";
import "package:loure/client/metadata.dart";

class EditorComponent extends StatefulWidget {
  const EditorComponent(
      {required this.onSubmit, super.key, this.hidden = false});

  final Function(String) onSubmit;
  final bool hidden;

  @override
  State<StatefulWidget> createState() => EditorComponentState();
}

class EditorComponentState extends State<EditorComponent> {
  late FleatherController _editorController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    this._editorController = blankController();
    _focusNode = FocusNode();

    this._editorController.document.changes.listen(this.onEdit);
  }

  FleatherController blankController() => FleatherController(
        document: ParchmentDocument.fromDelta(Delta()..insert("\n")),
      );

  void onEdit(ParchmentChange pc) async {
    if (pc.change.last.data == "@") {
      final inp = await showDialog<String>(
        context: context,
        builder: (final context) {
          return const Dialog(
            child: MentionSearcher(),
          );
        },
      );
      if (inp != null) {
        this
            ._editorController
            .compose(Delta()..delete(1), forceUpdateSelection: true);
        this
            ._editorController
            .compose(Delta()..insert(inp), forceUpdateSelection: true);
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    if (widget.hidden) return Container();

    return Row(
      children: [
        Expanded(
          child: FleatherEditor(
            padding: const EdgeInsets.all(Base.BASE_PADDING),
            autofocus: true,
            enableInteractiveSelection: true,
            controller: this._editorController,
            focusNode: this._focusNode,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () async {
            final success = await widget
                .onSubmit(this._editorController.document.toPlainText());
            if (success) {
              this._editorController = blankController();
            }
          },
        ),
      ],
    );
  }
}

class MentionSearcher extends StatefulWidget {
  const MentionSearcher({super.key});

  @override
  State<StatefulWidget> createState() {
    return MentionSearcherState();
  }
}

class MentionSearcherState extends State<MentionSearcher> {
  List<Widget> results = [];

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    this._controller.addListener(this.handleSearch);
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxWidth: min(120, MediaQuery.of(context).size.width * 0.80)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            controller: this._controller,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: "search Nostr user",
            ),
          ),
          SingleChildScrollView(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(
                top: Base.BASE_PADDING_HALF,
                bottom: Base.BASE_PADDING_HALF,
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: this.results,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void handleSearch() async {
    results.clear();

    final text = this._controller.text;
    if (text.length >= 2) {
      final list = await DB.getDB(null).query("metadata",
          where: "event like '%' || ? || '%' LIMIT 7", whereArgs: [text]);
      setState(() {
        results = list
            .map((final row) => UserItemComponent(Metadata.fromEvent(
                Event.fromJson(jsonDecode(row["event"] as String)))))
            .toList();
      });
    }
  }
}

class UserItemComponent extends StatelessWidget {
  const UserItemComponent(
    this.metadata, {
    super.key,
  });
  static const double IMAGE_WIDTH = 36;
  final Metadata metadata;

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;

    Widget? imageWidget;
    if (metadata.picture != null && metadata.picture != "") {
      imageWidget = ImageComponent(
        imageUrl: metadata.picture!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (final context, final url) =>
            const CircularProgressIndicator(),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.pop(context, "nostr:${NIP19.encodePubKey(metadata.pubkey)}");
      },
      child: Container(
        color: cardColor,
        margin: const EdgeInsets.only(
            left: Base.BASE_PADDING, right: Base.BASE_PADDING),
        padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
        child: Row(
          children: [
            Container(
              alignment: Alignment.center,
              height: IMAGE_WIDTH,
              width: IMAGE_WIDTH,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
                color: Colors.grey,
              ),
              child: imageWidget,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.shortName(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
