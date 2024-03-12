import 'package:flutter/material.dart';
import 'package:nostrmo/util/router_util.dart';

class ComfirmDialog {
  static Future<bool?> show(BuildContext context, String content) async {
    return await showDialog<bool>(
        context: context,
        builder: (context) {
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
