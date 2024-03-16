import "package:flutter/material.dart";
import "package:loure/util/router_util.dart";

class ConfirmDialog {
  static Future<bool?> show(
      final BuildContext context, final String content) async {
    return await showDialog<bool>(
        context: context,
        builder: (final context) {
          return AlertDialog(
            title: const Text("Notice"),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              TextButton(
                child: const Text("Confirm"),
                onPressed: () async {
                  RouterUtil.back(context, true);
                },
              ),
            ],
          );
        });
  }
}
