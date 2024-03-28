import "package:flutter/material.dart";

import "package:loure/client/metadata.dart";

// ignore: must_be_immutable
class Nip05ValidComponent extends StatefulWidget {
  Nip05ValidComponent({required this.metadata, super.key});
  Metadata metadata;

  @override
  State<StatefulWidget> createState() {
    return Nip05ValidComponentState();
  }
}

class Nip05ValidComponentState extends State<Nip05ValidComponent> {
  Future<bool?>? nip05ValidFuture;

  @override
  void initState() {
    super.initState();
    this.nip05ValidFuture = widget.metadata.validateNIP05();
  }

  @override
  Widget build(final BuildContext context) {
    final themeData = Theme.of(context);
    final mainColor = themeData.primaryColor;
    final smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return FutureBuilder(
      future: this.nip05ValidFuture,
      initialData: null,
      builder: (final context, final snapshot) {
        if (snapshot.data == null) {
          return const SizedBox(
            width: 0,
            height: 0,
          );
        }

        return Icon(
          Icons.check_circle,
          color: snapshot.data == true ? mainColor : Colors.yellow,
          size: smallTextSize,
        );
      },
    );
  }
}
