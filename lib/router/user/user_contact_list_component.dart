import 'package:flutter/material.dart';

import 'package:loure/main.dart';
import 'package:loure/client/nip02/contact.dart';
import 'package:loure/client/nip02/cust_contact_list.dart';
import 'package:loure/component/user/metadata_component.dart';
import 'package:loure/consts/base.dart';
import 'package:loure/consts/router_path.dart';
import 'package:loure/data/metadata.dart';
import 'package:loure/util/platform_util.dart';
import 'package:loure/util/router_util.dart';

class UserContactListComponent extends StatefulWidget {
  final CustContactList contactList;

  const UserContactListComponent({super.key, required this.contactList});

  @override
  State<StatefulWidget> createState() {
    return _UserContactListComponent();
  }
}

class _UserContactListComponent extends State<UserContactListComponent> {
  final ScrollController _controller = ScrollController();

  List<Contact>? list;
  List<Future<Metadata>>? metadataFutures;

  @override
  void initState() {
    super.initState();
    this.list = widget.contactList.list().toList();
    this.metadataFutures =
        list!.map((contact) => metadataLoader.load(contact.publicKey)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (this.metadataFutures == null) return Container();

    Widget main = ListView.builder(
      controller: _controller,
      itemBuilder: (context, index) {
        var contact = list![index];
        return Container(
          margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
          child: GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.USER, contact.publicKey);
            },
            behavior: HitTestBehavior.translucent,
            child: FutureBuilder(
              future: this.metadataFutures![index],
              initialData: Metadata.blank(contact.publicKey),
              builder: (context, snapshot) {
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
        onVerticalDragUpdate: (detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return main;
  }
}
