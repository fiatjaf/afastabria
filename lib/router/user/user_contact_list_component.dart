import "package:flutter/material.dart";

import "package:loure/client/nip02/contact.dart";
import "package:loure/client/nip02/cust_contact_list.dart";
import "package:loure/component/user/metadata_component.dart";
import "package:loure/consts/base.dart";
import "package:loure/consts/router_path.dart";
import "package:loure/data/metadata.dart";
import "package:loure/main.dart";
import "package:loure/util/platform_util.dart";
import "package:loure/util/router_util.dart";

class UserContactListComponent extends StatefulWidget {
  const UserContactListComponent({required this.contactList, super.key});
  final CustContactList contactList;

  @override
  State<StatefulWidget> createState() {
    return _UserContactListComponent();
  }
}

class _UserContactListComponent extends State<UserContactListComponent> {
  final ScrollController _controller = ScrollController();

  List<Contact>? list;

  @override
  void initState() {
    super.initState();
    this.list = widget.contactList.list().toList();
  }

  @override
  Widget build(final BuildContext context) {
    if (this.list == null) return Container();

    Widget main = ListView.builder(
      controller: _controller,
      itemBuilder: (final context, final index) {
        final contact = list![index];
        return Container(
          margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
          child: GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.USER, contact.publicKey);
            },
            behavior: HitTestBehavior.translucent,
            child: FutureBuilder(
              future: metadataLoader.load(contact.publicKey),
              initialData: Metadata.blank(contact.publicKey),
              builder: (final context, final snapshot) {
                return MetadataComponent(
                  pubKey: contact.publicKey,
                  metadata: snapshot.data,
                  jumpable: true,
                );
              },
            ),
          ),
        );
      },
      itemCount: list!.length,
    );

    if (PlatformUtil.isTableMode()) {
      main = GestureDetector(
        onVerticalDragUpdate: (final detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return main;
  }
}
