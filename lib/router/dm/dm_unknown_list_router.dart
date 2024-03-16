import "package:flutter/material.dart";
import "package:pointycastle/ecc/api.dart";
import "package:provider/provider.dart";

import "package:loure/provider/dm_provider.dart";
import "package:loure/router/dm/dm_session_list_item_component.dart";

class DMUnknownListRouter extends StatefulWidget {
  DMUnknownListRouter({required this.agreement, super.key});
  ECDHBasicAgreement agreement;

  @override
  State<StatefulWidget> createState() {
    return _DMUnknownListRouter();
  }
}

class _DMUnknownListRouter extends State<DMUnknownListRouter> {
  @override
  Widget build(final BuildContext context) {
    final dmProvider = Provider.of<DMProvider>(context);
    final details = dmProvider.unknownList;

    return Container(
      child: ListView.builder(
        itemBuilder: (final context, final index) {
          if (index >= details.length) {
            return null;
          }

          final detail = details[index];
          return DMSessionListItemComponent(
            detail: detail,
            agreement: widget.agreement,
          );
        },
        itemCount: details.length,
      ),
    );
  }
}
