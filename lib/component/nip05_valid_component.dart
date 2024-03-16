import 'package:flutter/material.dart';

import 'package:loure/data/metadata.dart';

// ignore: must_be_immutable
class Nip05ValidComponent extends StatefulWidget {
  Metadata metadata;

  Nip05ValidComponent({super.key, required this.metadata});

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
    this.nip05ValidFuture = widget.metadata.valid();
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return FutureBuilder(
      future: this.nip05ValidFuture,
      initialData: null,
      builder: (context, snapshot) {
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
